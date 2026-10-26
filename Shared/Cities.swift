import Foundation

struct City: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var code: String
    var timeZoneIdentifier: String
}

enum CityCatalog {
    static let localID = "local"

    /// Time zone id, display name, three-letter board code.
    private static let table: [(String, String, String)] = [
        ("America/New_York", "New York", "NYC"),
        ("America/Chicago", "Chicago", "CHI"),
        ("America/Denver", "Denver", "DEN"),
        ("America/Los_Angeles", "Los Angeles", "LAX"),
        ("America/Phoenix", "Phoenix", "PHX"),
        ("America/Anchorage", "Anchorage", "ANC"),
        ("Pacific/Honolulu", "Honolulu", "HNL"),
        ("America/Toronto", "Toronto", "YYZ"),
        ("America/Vancouver", "Vancouver", "YVR"),
        ("America/Edmonton", "Edmonton", "YEG"),
        ("America/Winnipeg", "Winnipeg", "YWG"),
        ("America/Halifax", "Halifax", "YHZ"),
        ("America/St_Johns", "St Johns", "YYT"),
        ("America/Mexico_City", "Mexico City", "MEX"),
        ("America/Cancun", "Cancun", "CUN"),
        ("America/Bogota", "Bogota", "BOG"),
        ("America/Lima", "Lima", "LIM"),
        ("America/Santiago", "Santiago", "SCL"),
        ("America/Sao_Paulo", "Sao Paulo", "SAO"),
        ("America/Argentina/Buenos_Aires", "Buenos Aires", "BUE"),
        ("America/Caracas", "Caracas", "CCS"),
        ("Europe/London", "London", "LON"),
        ("Europe/Dublin", "Dublin", "DUB"),
        ("Europe/Lisbon", "Lisbon", "LIS"),
        ("Europe/Madrid", "Madrid", "MAD"),
        ("Europe/Paris", "Paris", "PAR"),
        ("Europe/Amsterdam", "Amsterdam", "AMS"),
        ("Europe/Brussels", "Brussels", "BRU"),
        ("Europe/Zurich", "Zurich", "ZRH"),
        ("Europe/Rome", "Rome", "ROM"),
        ("Europe/Berlin", "Berlin", "BER"),
        ("Europe/Vienna", "Vienna", "VIE"),
        ("Europe/Warsaw", "Warsaw", "WAW"),
        ("Europe/Stockholm", "Stockholm", "ARN"),
        ("Europe/Oslo", "Oslo", "OSL"),
        ("Europe/Copenhagen", "Copenhagen", "CPH"),
        ("Europe/Helsinki", "Helsinki", "HEL"),
        ("Europe/Athens", "Athens", "ATH"),
        ("Europe/Istanbul", "Istanbul", "IST"),
        ("Europe/Moscow", "Moscow", "MOW"),
        ("Europe/Kyiv", "Kyiv", "IEV"),
        ("Africa/Cairo", "Cairo", "CAI"),
        ("Africa/Johannesburg", "Johannesburg", "JNB"),
        ("Africa/Lagos", "Lagos", "LOS"),
        ("Africa/Nairobi", "Nairobi", "NBO"),
        ("Asia/Dubai", "Dubai", "DXB"),
        ("Asia/Jerusalem", "Jerusalem", "JRS"),
        ("Asia/Riyadh", "Riyadh", "RUH"),
        ("Asia/Tehran", "Tehran", "THR"),
        ("Asia/Karachi", "Karachi", "KHI"),
        ("Asia/Kolkata", "Kolkata", "CCU"),
        ("Asia/Dhaka", "Dhaka", "DAC"),
        ("Asia/Bangkok", "Bangkok", "BKK"),
        ("Asia/Jakarta", "Jakarta", "JKT"),
        ("Asia/Ho_Chi_Minh", "Ho Chi Minh", "SGN"),
        ("Asia/Singapore", "Singapore", "SIN"),
        ("Asia/Hong_Kong", "Hong Kong", "HKG"),
        ("Asia/Shanghai", "Shanghai", "SHA"),
        ("Asia/Taipei", "Taipei", "TPE"),
        ("Asia/Seoul", "Seoul", "SEL"),
        ("Asia/Tokyo", "Tokyo", "TYO"),
        ("Australia/Perth", "Perth", "PER"),
        ("Australia/Adelaide", "Adelaide", "ADL"),
        ("Australia/Sydney", "Sydney", "SYD"),
        ("Australia/Melbourne", "Melbourne", "MEL"),
        ("Pacific/Auckland", "Auckland", "AKL"),
        ("Pacific/Fiji", "Fiji", "SUV"),
        ("UTC", "UTC", "UTC")
    ]

    static let local = City(id: localID, name: "This Mac", code: "MAC", timeZoneIdentifier: localID)

    static let all: [City] = [local] + table.map {
        City(id: $0.0, name: $0.1, code: $0.2, timeZoneIdentifier: $0.0)
    }

    static func stored(_ id: String) -> City? {
        all.first { $0.id == id }
    }

    /// City shown on a board. "This Mac" follows the Mac's current zone when it matches the catalog.
    static func resolved(_ id: String) -> City {
        if id == localID {
            let identifier = TimeZone.current.identifier
            if let match = table.first(where: { $0.0 == identifier }) {
                return City(id: localID, name: match.1, code: match.2, timeZoneIdentifier: identifier)
            }
            return City(id: localID, name: "This Mac", code: "MAC", timeZoneIdentifier: identifier)
        }
        return stored(id) ?? City(id: id, name: "Unknown", code: "---", timeZoneIdentifier: "UTC")
    }

    static func timeZone(for id: String) -> TimeZone {
        let identifier = resolved(id).timeZoneIdentifier
        if identifier == localID { return .current }
        return TimeZone(identifier: identifier) ?? .current
    }
}
