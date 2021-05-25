import Foundation
import Humidity

enum RuuviTagSensorRecordSource: String {
    case unknown
    case advertisement
    case log
    case heartbeat
    case ruuviNetwork
    case weatherProvider
}

protocol RuuviTagSensorRecord {
    var ruuviTagId: String { get }
    var date: Date { get }
    var source: RuuviTagSensorRecordSource { get }
    var macId: MACIdentifier? { get }
    var rssi: Int? { get }
    var temperature: Temperature? { get }
    var humidity: Humidity? { get }
    var pressure: Pressure? { get }
    // v3 & v5
    var acceleration: Acceleration? { get }
    var voltage: Voltage? { get }
    // v5
    var movementCounter: Int? { get }
    var measurementSequenceNumber: Int? { get }
    var txPower: Int? { get }

    // offset correction
    var temperatureOffset: Double { get }
    var humidityOffset: Double { get }
    var pressureOffset: Double { get }
}

extension RuuviTagSensorRecord {
    var id: String {
        return ruuviTagId + "\(date.timeIntervalSince1970)"
    }

    var any: AnyRuuviTagSensorRecord {
        return AnyRuuviTagSensorRecord(object: self)
    }

    func with(macId: MACIdentifier) -> RuuviTagSensorRecord {
        return RuuviTagSensorRecordStruct(
            ruuviTagId: macId.value,
            date: date,
            source: source,
            macId: macId,
            rssi: rssi,
            temperature: temperature,
            humidity: humidity,
            pressure: pressure,
            acceleration: acceleration,
            voltage: voltage,
            movementCounter: movementCounter,
            measurementSequenceNumber: measurementSequenceNumber,
            txPower: txPower,
            temperatureOffset: temperatureOffset,
            humidityOffset: humidityOffset,
            pressureOffset: pressureOffset
        )
    }
}

extension RuuviTagSensorRecord {
    func with(source: RuuviTagSensorRecordSource) -> RuuviTagSensorRecord {
        return RuuviTagSensorRecordStruct(
            ruuviTagId: ruuviTagId,
            date: date,
            source: source,
            macId: macId,
            rssi: rssi,
            temperature: temperature,
            humidity: humidity,
            pressure: pressure,
            acceleration: acceleration,
            voltage: voltage,
            movementCounter: movementCounter,
            measurementSequenceNumber: measurementSequenceNumber,
            txPower: txPower,
            temperatureOffset: temperatureOffset,
            humidityOffset: humidityOffset,
            pressureOffset: pressureOffset
        )
    }

    func with(sensorSettings: SensorSettings?) -> RuuviTagSensorRecord {
        return RuuviTagSensorRecordStruct(
            ruuviTagId: ruuviTagId,
            date: date,
            source: source,
            macId: macId,
            rssi: rssi,
            temperature: temperature?.withSensorSettings(sensorSettings: sensorSettings),
            humidity: humidity?.withSensorSettings(sensorSettings: sensorSettings),
            pressure: pressure?.withSensorSettings(sensorSettings: sensorSettings),
            acceleration: acceleration,
            voltage: voltage,
            movementCounter: movementCounter,
            measurementSequenceNumber: measurementSequenceNumber,
            txPower: txPower,
            temperatureOffset: sensorSettings?.temperatureOffset ?? 0.0,
            humidityOffset: sensorSettings?.humidityOffset ?? 0.0,
            pressureOffset: sensorSettings?.pressureOffset ?? 0.0
        )
    }
}

struct RuuviTagSensorRecordStruct: RuuviTagSensorRecord {
    var ruuviTagId: String
    var date: Date
    var source: RuuviTagSensorRecordSource
    var macId: MACIdentifier?
    var rssi: Int?
    var temperature: Temperature?
    var humidity: Humidity?
    var pressure: Pressure?
    // v3 & v5
    var acceleration: Acceleration?
    var voltage: Voltage?
    // v5
    var movementCounter: Int?
    var measurementSequenceNumber: Int?
    var txPower: Int?

    // offset correction
    var temperatureOffset: Double
    var humidityOffset: Double
    var pressureOffset: Double
}

struct AnyRuuviTagSensorRecord: RuuviTagSensorRecord, Equatable, Hashable {
    var object: RuuviTagSensorRecord

    var ruuviTagId: String {
        return object.ruuviTagId
    }

    var date: Date {
        return object.date
    }

    var source: RuuviTagSensorRecordSource {
        return object.source
    }

    var macId: MACIdentifier? {
        return object.macId
    }

    var rssi: Int? {
        return object.rssi
    }

    var temperature: Temperature? {
        return object.temperature
    }

    var humidity: Humidity? {
        return object.humidity
    }

    var pressure: Pressure? {
        return object.pressure
    }

    var acceleration: Acceleration? {
        return object.acceleration
    }

    var voltage: Voltage? {
        return object.voltage
    }

    var movementCounter: Int? {
        return object.movementCounter
    }

    var measurementSequenceNumber: Int? {
        return object.measurementSequenceNumber
    }

    var txPower: Int? {
        return object.txPower
    }

    var temperatureOffset: Double {
        return object.temperatureOffset
    }

    var humidityOffset: Double {
        return object.humidityOffset
    }

    var pressureOffset: Double {
        return object.pressureOffset
    }

    static func == (lhs: AnyRuuviTagSensorRecord, rhs: AnyRuuviTagSensorRecord) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
