import Foundation
import RuuviOntology

public struct RuuviCloudApiUserResponse: Decodable {
    public let email: String
    public var sensors: [RuuviCloudApiSensor]
}

public struct RuuviCloudApiSensor: Decodable {
    public let sensorId: String
    public let sensorOwner: String
    public let pictureUrl: String
    public let name: String
    public let isPublic: Bool
    public var isOwner: Bool = false
    public let temperatureOffset: Double? // in degrees
    public let humidityOffset: Double? // in percents
    public let pressureOffset: Double? // in Pa

    enum CodingKeys: String, CodingKey {
        case sensorId = "sensor"
        case sensorOwner = "owner"
        case name
        case pictureUrl = "picture"
        case isPublic = "public"
        case temperatureOffset = "offsetTemperature"
        case humidityOffset = "offsetHumidity"
        case pressureOffset = "offsetPressure"
    }
}

extension RuuviCloudApiSensor: CloudSensor {
    public var offsetTemperature: Double? {
        return temperatureOffset
    }

    // on cloud in percent, locally in fraction of one
    public var offsetHumidity: Double? {
        if let humidityOffset = humidityOffset {
            return humidityOffset / 100.0
        } else {
            return nil
        }
    }

    // on cloud in Pa, locally in hPa
    public var offsetPressure: Double? {
        if let pressureOffset = pressureOffset {
            return pressureOffset / 100.0
        } else {
            return nil
        }
    }

    public var picture: URL? {
        return URL(string: pictureUrl)
    }

    public var owner: String? {
        return sensorOwner
    }

    public var isClaimed: Bool {
        return isOwner
    }

    public var id: String {
        return sensorId
    }
}
