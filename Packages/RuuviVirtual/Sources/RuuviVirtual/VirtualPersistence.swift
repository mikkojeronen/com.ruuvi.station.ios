import Foundation
import Future
import CoreLocation
import RuuviOntology

public protocol VirtualPersistence {
    var isCurrentLocationVirtualTagExists: Bool { get }

    func readAll() -> Future<[AnyVirtualTagSensor], VirtualPersistenceError>

    func readLast(
        _ virtualTag: VirtualTagSensor
    ) -> Future<VirtualTagSensorRecord?, VirtualPersistenceError>

    func readOne(
        _ id: String
    ) -> Future<AnyVirtualTagSensor, VirtualPersistenceError>

    func deleteAllRecords(
        _ ruuviTagId: String,
        before date: Date
    ) -> Future<Bool, VirtualPersistenceError>

    func persist(
        provider: VirtualProvider,
        name: String
    ) -> Future<VirtualProvider, VirtualPersistenceError>

    func persist(
        provider: VirtualProvider,
        location: Location
    ) -> Future<VirtualProvider, VirtualPersistenceError>

    func remove(sensor: VirtualSensor) -> Future<Bool, VirtualPersistenceError>

    func update(
        name: String,
        of sensor: VirtualSensor
    ) -> Future<Bool, VirtualPersistenceError>

    func update(
        location: Location,
        of sensor: VirtualSensor
    ) -> Future<Bool, VirtualPersistenceError>

    func clearLocation(
        of sensor: VirtualSensor,
        name: String
    ) -> Future<Bool, VirtualPersistenceError>

    @discardableResult
    func persist(
        currentLocation: Location,
        data: VirtualData
    ) -> Future<VirtualData, VirtualPersistenceError>

    @discardableResult
    func persist(
        location: Location,
        data: VirtualData
    ) -> Future<VirtualData, VirtualPersistenceError>
}
