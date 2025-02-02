import Foundation
import RuuviDFU
import Combine
#if canImport(NordicDFU)
import NordicDFU
#endif
#if canImport(iOSDFULibrary)
import iOSDFULibrary
#endif

public struct RuuviDFUImpl: RuuviDFU {
    public static let shared = RuuviDFUImpl()

    private let scanner = DfuScanner()
    private let flasher = DfuFlasher()

    @discardableResult
    public func scan<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, DFUDevice) -> Void
    ) -> RuuviDFUToken {
        return scanner.scan(observer, closure: closure)
    }

    @discardableResult
    public func lost<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, DFUDevice) -> Void
    ) -> RuuviDFUToken {
        return scanner.lost(observer, closure: closure)
    }

    public func firmwareFromUrl(url: URL) -> DFUFirmware? {
        return DFUFirmware(urlToZipFile: url, type: .softdeviceBootloaderApplication)
    }

    public func flashFirmware(
        uuid: String,
        with firmware: DFUFirmware
    ) -> AnyPublisher<FlashResponse, Error> {
        return flasher.flashFirmware(uuid: uuid, with: firmware)
    }

    public func stopFlashFirmware(device: DFUDevice) -> Bool {
        return flasher.stopFlashFirmware(device: device)
    }
}
