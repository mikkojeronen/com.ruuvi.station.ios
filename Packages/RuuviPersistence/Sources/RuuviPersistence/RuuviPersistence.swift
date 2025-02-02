import Future
import Foundation
import RuuviOntology

public protocol RuuviPersistence {
    func create(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RuuviPersistenceError>
    func update(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RuuviPersistenceError>
    func delete(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RuuviPersistenceError>
    func deleteAllRecords(_ ruuviTagId: String) -> Future<Bool, RuuviPersistenceError>
    func deleteAllRecords(_ ruuviTagId: String, before date: Date) -> Future<Bool, RuuviPersistenceError>
    func create(_ record: RuuviTagSensorRecord) -> Future<Bool, RuuviPersistenceError>
    func create(_ records: [RuuviTagSensorRecord]) -> Future<Bool, RuuviPersistenceError>
    func readAll() -> Future<[AnyRuuviTagSensor], RuuviPersistenceError>
    func readAll(_ ruuviTagId: String) -> Future<[RuuviTagSensorRecord], RuuviPersistenceError>
    func readAll(
        _ ruuviTagId: String,
        with interval: TimeInterval
    ) -> Future<[RuuviTagSensorRecord], RuuviPersistenceError>
    func readLast(_ ruuviTagId: String, from: TimeInterval) -> Future<[RuuviTagSensorRecord], RuuviPersistenceError>
    func readLast(_ ruuviTag: RuuviTagSensor) -> Future<RuuviTagSensorRecord?, RuuviPersistenceError>
    func readOne(_ ruuviTagId: String) -> Future<AnyRuuviTagSensor, RuuviPersistenceError>
    func getStoredTagsCount() -> Future<Int, RuuviPersistenceError>
    func getStoredMeasurementsCount() -> Future<Int, RuuviPersistenceError>

    func read(
        _ ruuviTagId: String,
        after date: Date,
        with interval: TimeInterval
    ) -> Future<[RuuviTagSensorRecord], RuuviPersistenceError>

    func readSensorSettings(
        _ ruuviTag: RuuviTagSensor
    ) -> Future<SensorSettings?, RuuviPersistenceError>

    func updateOffsetCorrection(
        type: OffsetCorrectionType,
        with value: Double?,
        of ruuviTag: RuuviTagSensor,
        lastOriginalRecord record: RuuviTagSensorRecord?
    ) -> Future<SensorSettings, RuuviPersistenceError>

    func deleteOffsetCorrection(
        ruuviTag: RuuviTagSensor
    ) -> Future<Bool, RuuviPersistenceError>

    func save(
        sensorSettings: SensorSettings
    ) -> Future<SensorSettings, RuuviPersistenceError>
}
