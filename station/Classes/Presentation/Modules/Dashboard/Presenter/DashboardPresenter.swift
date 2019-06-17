import Foundation
import RealmSwift
import BTKit

class DashboardPresenter: DashboardModuleInput {
    weak var view: DashboardViewInput!
    var router: DashboardRouterInput!
    var realmContext: RealmContext!
    var errorPresenter: ErrorPresenter!
    var settings: Settings!
    var backgroundPersistence: BackgroundPersistence!
    var ruuviTagPersistence: RuuviTagPersistence!
    
    private let scanner = Ruuvi.scanner
    private var ruuviTagsToken: NotificationToken?
    private var observeTokens = [ObservationToken]()
    private var ruuviTags: Results<RuuviTagRealm>? {
        didSet {
            if let ruuviTags = ruuviTags {
                view.viewModels = ruuviTags.map( {
                    return DashboardRuuviTagViewModel(uuid: $0.uuid, name: $0.name, celsius: $0.data.last?.celsius ?? 0, humidity: $0.data.last?.humidity ?? 0, pressure: $0.data.last?.pressure ?? 0, rssi: $0.data.last?.rssi ?? 0, version: $0.version, voltage: $0.data.last?.voltage.value, background: backgroundPersistence.background(for: $0.uuid))
                } )
            } else {
                view.viewModels = []
            }
        }
    }
    
    deinit {
        ruuviTagsToken?.invalidate()
        observeTokens.forEach( { $0.invalidate() } )
    }
}

extension DashboardPresenter: DashboardViewOutput {
    func viewDidLoad() {
        startObservingRuuviTags()
    }
    
    func viewWillAppear() {
        startScanningRuuviTags()
    }
    
    func viewWillDisappear() {
        stopScanningRuuviTags()
    }
    
    func viewDidTriggerMenu() {
        router.openMenu()
    }
    
    func viewDidTriggerSettings(for viewModel: DashboardRuuviTagViewModel) {
        view.showMenu(for: viewModel)
    }
    
    func viewDidAskToRemove(viewModel: DashboardRuuviTagViewModel) {
        if let ruuviTag = ruuviTags?.first(where: { $0.uuid == viewModel.uuid}) {
            let operation = ruuviTagPersistence.delete(ruuviTag: ruuviTag)
            operation.on(failure: { [weak self] (error) in
                self?.errorPresenter.present(error: error)
            })
        }
    }
    
    func viewDidAskToRename(viewModel: DashboardRuuviTagViewModel) {
        view.showRenameDialog(for: viewModel)
    }
    
    func viewDidChangeName(of viewModel: DashboardRuuviTagViewModel, to name: String) {
        if let ruuviTag = ruuviTags?.first(where: { $0.uuid == viewModel.uuid}) {
            let operation = ruuviTagPersistence.update(name: name, of: ruuviTag)
            operation.on(failure: { [weak self] (error) in
                self?.errorPresenter.present(error: error)
            })
        }
    }
}

extension DashboardPresenter {
    private func startScanningRuuviTags() {
        observeTokens.forEach( { $0.invalidate() } )
        observeTokens.removeAll()
        for viewModel in view.viewModels {
            observeTokens.append(scanner.observe(self, uuid: viewModel.uuid) { (observer, device) in
                if let tagData = device.ruuvi?.tag {
                    let model = DashboardRuuviTagViewModel(uuid: viewModel.uuid, name: viewModel.name, celsius: tagData.celsius, humidity: tagData.humidity, pressure: tagData.pressure, rssi: tagData.rssi, version: tagData.version, voltage: tagData.voltage, background: viewModel.background)
                    observer.view.reload(viewModel: model)
                }
            })
        }
    }
    
    private func stopScanningRuuviTags() {
        observeTokens.forEach( { $0.invalidate() } )
        observeTokens.removeAll()
    }
    
    private func startObservingRuuviTags() {
        let ruuviTags = realmContext.main.objects(RuuviTagRealm.self)
        ruuviTagsToken = ruuviTags.observe { [weak self] (change) in
            switch change {
            case .initial(let ruuviTags):
                self?.ruuviTags = ruuviTags
                self?.startScanningRuuviTags()
            case .update(let ruuviTags, _, _, _):
                self?.ruuviTags = ruuviTags
                self?.startScanningRuuviTags()
            case .error(let error):
                self?.errorPresenter.present(error: error)
            }
        }
    }
}