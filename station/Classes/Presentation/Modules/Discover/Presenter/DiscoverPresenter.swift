import Foundation
import BTKit
import UIKit
import Future
import RuuviOntology
import RuuviContext
import RuuviReactor
import RuuviLocal
import RuuviService
import RuuviVirtual
import RuuviCore

class DiscoverPresenter: NSObject, DiscoverModuleInput {
    weak var view: DiscoverViewInput!
    var router: DiscoverRouterInput!
    var virtualReactor: VirtualReactor!
    var errorPresenter: ErrorPresenter!
    var activityPresenter: ActivityPresenter!
    var virtualService: VirtualService!
    var foreground: BTForeground!
    var permissionsManager: RuuviCorePermission!
    var permissionPresenter: PermissionPresenter!
    var ruuviReactor: RuuviReactor!
    var settings: RuuviLocalSettings!
    var ruuviOwnershipService: RuuviServiceOwnership!

    private var ruuviTags = Set<RuuviTag>()
    private var persistedVirtualSensors: [VirtualTagSensor]! {
        didSet {
            view.savedWebTagProviders = persistedVirtualSensors.map({ $0.provider })
            updateCloseButtonVisibilityState()
        }
    }
    private var persistedSensors: [RuuviTagSensor]! {
        didSet {
            view.savedRuuviTagIds = persistedSensors.map({ $0.luid?.any })
            updateCloseButtonVisibilityState()
        }
    }
    private var reloadTimer: Timer?
    private var scanToken: ObservationToken?
    private var stateToken: ObservationToken?
    private var lostToken: ObservationToken?
    private var virtualReactorToken: VirtualReactorToken?
    private var persistedReactorToken: RuuviReactorToken?
    private let ruuviLogoImage = UIImage(named: "ruuvi_logo")
    private var isOpenedFromWelcome: Bool = true
    private var lastSelectedWebTag: DiscoverVirtualTagViewModel?
    private weak var output: DiscoverModuleOutput?

    deinit {
        reloadTimer?.invalidate()
        scanToken?.invalidate()
        stateToken?.invalidate()
        lostToken?.invalidate()
        virtualReactorToken?.invalidate()
        persistedReactorToken?.invalidate()
    }

    func configure(isOpenedFromWelcome: Bool, output: DiscoverModuleOutput?) {
        self.isOpenedFromWelcome = isOpenedFromWelcome
        self.output = output
    }

    func dismiss(completion: (() -> Void)?) {
        router.dismiss(completion: completion)
    }
}

// MARK: - DiscoverViewOutput
extension DiscoverPresenter: DiscoverViewOutput {
    func viewDidLoad() {
        let current = DiscoverVirtualTagViewModel(
            provider: .openWeatherMap,
            locationType: .current,
            icon: UIImage(named: "icon-webtag-current")
        )
        let manual = DiscoverVirtualTagViewModel(
            provider: .openWeatherMap,
            locationType: .manual,
            icon: UIImage(named: "icon-webtag-map")
        )
        if virtualService.isCurrentLocationVirtualTagExists {
            view.virtualTags = [manual]
        } else {
            view.virtualTags = [manual, current]
        }
        view.isBluetoothEnabled = foreground.bluetoothState == .poweredOn
        if !view.isBluetoothEnabled
            && !isOpenedFromWelcome
            && foreground.bluetoothState != .unknown {
            view.showBluetoothDisabled()
        }

        startObservingPersistedRuuviSensors()
        startObservingPersistedWebTags()
    }

    func viewWillAppear() {
        startObservingBluetoothState()
        startScanning()
        startReloading()
        startObservingLost()
    }

    func viewWillDisappear() {
        stopObservingBluetoothState()
        stopScanning()
        stopReloading()
        stopObservingLost()
    }

    func viewDidChoose(device: DiscoverRuuviTagViewModel, displayName: String) {
        if let ruuviTag = ruuviTags.first(where: { $0.luid?.any != nil && $0.luid?.any == device.luid?.any }) {
            ruuviOwnershipService.add(
                sensor: ruuviTag.with(name: displayName),
                record: ruuviTag.with(source: .advertisement))
                .on(success: { [weak self] _ in
                    guard let sSelf = self else { return }
                    if sSelf.isOpenedFromWelcome {
                        sSelf.router.openCards()
                    } else {
                        sSelf.output?.discover(module: sSelf, didAdd: ruuviTag)
                    }
                }, failure: { [weak self] error in
                    self?.errorPresenter.present(error: error)
                })
        }
    }

    func viewDidChoose(webTag: DiscoverVirtualTagViewModel) {
        switch webTag.locationType {
        case .current:
            if permissionsManager.isLocationPermissionGranted {
                persistWebTag(with: webTag.provider)
            } else {
                permissionsManager.requestLocationPermission { [weak self] (granted) in
                    if granted {
                        self?.persistWebTag(with: webTag.provider)
                    } else {
                        self?.permissionPresenter.presentNoLocationPermission()
                    }
                }
            }
        case .manual:
            lastSelectedWebTag = webTag
            router.openLocationPicker(output: self)
        }
    }

    func viewDidTapOnGetMoreSensors() {
        router.openRuuviWebsite()
    }

    func viewDidTriggerClose() {
        if isOpenedFromWelcome {
            router.openCards()
        } else {
            router.dismiss()
        }
    }

    func viewDidTapOnWebTagInfo() {
        view.showWebTagInfoDialog()
    }
}

// MARK: - LocationPickerModuleOutput
extension DiscoverPresenter: LocationPickerModuleOutput {
    func locationPicker(module: LocationPickerModuleInput, didPick location: Location) {
        module.dismiss { [weak self] in
            guard let webTag = self?.lastSelectedWebTag else { return }
            guard let operation = self?.virtualService
                .add(provider: webTag.provider,
                     location: location) else { return }
            operation.on(success: { [weak self] _ in
                guard let sSelf = self else { return }
                if sSelf.isOpenedFromWelcome {
                    sSelf.router.openCards()
                } else {
                    sSelf.output?.discover(module: sSelf, didAddWebTag: location)
                }
            }, failure: { [weak self] error in
                self?.errorPresenter.present(error: error)
            })
            self?.lastSelectedWebTag = nil
        }
    }
}

// MARK: - Private
extension DiscoverPresenter {
    private func persistWebTag(with provider: VirtualProvider) {
        let operation = virtualService.add(
            provider: provider,
            name: VirtualLocation.current.title
        )
        operation.on(success: { [weak self] _ in
            guard let sSelf = self else { return }
            if sSelf.isOpenedFromWelcome {
                sSelf.router.openCards()
            } else {
                sSelf.output?.discover(module: sSelf, didAddWebTag: provider)
            }
        }, failure: { [weak self] error in
            self?.errorPresenter.present(error: error)
        })
    }

    private func startObservingPersistedWebTags() {
        virtualReactorToken?.invalidate()
        virtualReactorToken = virtualReactor.observe { [weak self] change in
            switch change {
            case .initial(let persistedVirtualSensors):
                self?.persistedVirtualSensors = persistedVirtualSensors
            case .insert(let addedPersistedVirtualSensor):
                self?.persistedVirtualSensors.append(addedPersistedVirtualSensor)
            case .delete(let deletedPersistedVirtualSensor):
                self?.persistedVirtualSensors.removeAll(where: { $0.id == deletedPersistedVirtualSensor.id })
            case .error(let error):
                self?.errorPresenter.present(error: error)
            case .update:
                break
            }
        }
    }

    private func startObservingPersistedRuuviSensors() {
        persistedReactorToken = ruuviReactor.observe({ [weak self] (change) in
            switch change {
            case .initial(let sensors):
                guard let sSelf = self else { return }
                let sensors = sensors.reordered(by: sSelf.settings)
                self?.persistedSensors = sensors
            case .insert(let sensor):
                self?.persistedSensors.append(sensor)
            case .delete(let sensor):
                self?.persistedSensors.removeAll(where: {$0.any == sensor})
            default:
                return
            }
        })
    }

    private func startObservingLost() {
        lostToken = foreground.lost(self, options: [.lostDeviceDelay(10)], closure: { (observer, device) in
            if let ruuviTag = device.ruuvi?.tag {
                observer.ruuviTags.remove(ruuviTag)
            }
        })
    }

    private func stopObservingLost() {
        lostToken?.invalidate()
    }

    private func startObservingBluetoothState() {
        stateToken = foreground.state(self, closure: { (observer, state) in
            observer.view.isBluetoothEnabled = state == .poweredOn
            if state == .poweredOff {
                observer.ruuviTags.removeAll()
                observer.view.ruuviTags = []
                observer.view.showBluetoothDisabled()
            }
        })
    }

    private func stopObservingBluetoothState() {
        stateToken?.invalidate()
    }

    private func startScanning() {
        scanToken = foreground.scan(self) { (observer, device) in
            if let ruuviTag = device.ruuvi?.tag {
                // when mode is changed, the device dhould be replaced
                if let sameUUID = observer.ruuviTags.first(where: { $0.uuid == ruuviTag.uuid }), sameUUID != ruuviTag {
                    observer.ruuviTags.remove(sameUUID)
                }
                observer.ruuviTags.update(with: ruuviTag)
            }
        }
    }

    private func stopScanning() {
        scanToken?.invalidate()
    }

    private func startReloading() {
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] (_) in
            self?.updateViewDevices()
        })
        // don't wait for timer, reload after 0.5 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateViewDevices()
        }
    }

    private func stopReloading() {
        reloadTimer?.invalidate()
    }

    private func updateViewDevices() {
        view.ruuviTags = ruuviTags.map { (ruuviTag) -> DiscoverRuuviTagViewModel in
            if let persistedRuuviTag = persistedSensors
                .first(where: { $0.luid?.any != nil && $0.luid?.any == ruuviTag.luid?.any }) {
                return DiscoverRuuviTagViewModel(
                    luid: ruuviTag.luid?.any,
                    isConnectable: ruuviTag.isConnectable,
                    rssi: ruuviTag.rssi,
                    mac: ruuviTag.mac,
                    name: persistedRuuviTag.name,
                    logo: ruuviLogoImage
                )
            } else {
                return DiscoverRuuviTagViewModel(
                    luid: ruuviTag.luid?.any,
                    isConnectable: ruuviTag.isConnectable,
                    rssi: ruuviTag.rssi,
                    mac: ruuviTag.mac,
                    name: nil,
                    logo: ruuviLogoImage
                )
            }
        }
    }

    private func updateCloseButtonVisibilityState() {
        view.isCloseEnabled = true
    }
}
