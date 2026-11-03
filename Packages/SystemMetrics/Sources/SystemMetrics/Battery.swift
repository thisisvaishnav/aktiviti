import Foundation
import IOKit.ps
import IOKit

/// Snapshot of battery and power metrics.
public struct BatteryMetrics: Sendable, Equatable {
    public let percent: Double
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let timeRemainingMinutes: Int?
    public let powerDrawWatts: Double
    public let healthPercent: Double
    public let stateDescription: String
    public let cycleCount: Int
    public let adapterWatts: Int?
    public let adapterName: String?

    public init(
        percent: Double,
        isCharging: Bool,
        isPluggedIn: Bool,
        timeRemainingMinutes: Int?,
        powerDrawWatts: Double,
        healthPercent: Double,
        stateDescription: String,
        cycleCount: Int = 0,
        adapterWatts: Int? = nil,
        adapterName: String? = nil
    ) {
        self.percent = percent
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.timeRemainingMinutes = timeRemainingMinutes
        self.powerDrawWatts = powerDrawWatts
        self.healthPercent = healthPercent
        self.stateDescription = stateDescription
        self.cycleCount = cycleCount
        self.adapterWatts = adapterWatts
        self.adapterName = adapterName
    }
}

/// Reads power and battery status via IOKit.ps and AppleSmartBattery.
public enum BatteryReader {
    public static func read() -> BatteryMetrics {
        var cycleCount = 0
        var smartHealth = 100.0
        var smartPowerWatts = 0.0
        var smartAdapterWatts: Int? = nil
        var smartAdapterName: String? = nil

        // Query AppleSmartBattery for authentic hardware diagnostics
        let match = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, match)
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                cycleCount = dict["CycleCount"] as? Int ?? 0

                if let bData = dict["BatteryData"] as? [String: Any],
                   let full = bData["FullChargeCapacity"] as? Double,
                   let design = bData["DesignCapacity"] as? Double, design > 0 {
                    smartHealth = (full / design) * 100.0
                }

                if let telem = dict["PowerTelemetryData"] as? [String: Any],
                   let loadMW = telem["SystemLoad"] as? Double, loadMW > 0 {
                    smartPowerWatts = loadMW / 1000.0
                }

                if let ad = dict["AdapterDetails"] as? [String: Any] {
                    smartAdapterWatts = ad["Watts"] as? Int
                    smartAdapterName = ad["Name"] as? String
                }
            }
            IOObjectRelease(service)
        }

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            // Desktop Mac or no power source
            return BatteryMetrics(
                percent: 100.0,
                isCharging: false,
                isPluggedIn: true,
                timeRemainingMinutes: nil,
                powerDrawWatts: smartPowerWatts > 0 ? smartPowerWatts : 15.0,
                healthPercent: smartHealth,
                stateDescription: "Power Adapter",
                cycleCount: cycleCount,
                adapterWatts: smartAdapterWatts,
                adapterName: smartAdapterName
            )
        }

        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                let current = (desc[kIOPSCurrentCapacityKey as String] as? NSNumber)?.doubleValue ?? 100.0
                let max = (desc[kIOPSMaxCapacityKey as String] as? NSNumber)?.doubleValue ?? 100.0
                let pct = max > 0 ? (current / max) * 100.0 : 100.0

                let isCharging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false
                let powerSourceState = (desc[kIOPSPowerSourceStateKey as String] as? String) ?? "AC Power"
                let isPluggedIn = powerSourceState == (kIOPSACPowerValue as String)

                var timeRemaining: Int? = nil
                if let tr = desc[kIOPSTimeToEmptyKey as String] as? NSNumber {
                    let val = tr.intValue
                    if val > 0 && val < 10000 {
                        timeRemaining = val
                    }
                }

                var powerWatts = smartPowerWatts
                if powerWatts <= 0.1 {
                    if let volt = desc["Voltage"] as? NSNumber, let amp = desc["Current - Amperage"] as? NSNumber {
                        powerWatts = abs(volt.doubleValue * amp.doubleValue) / 1_000_000.0
                    }
                }
                if powerWatts <= 0.1 {
                    powerWatts = isPluggedIn ? 5.2 : 12.0
                }

                let stateDesc: String
                if isCharging {
                    stateDesc = "Charging"
                } else if isPluggedIn {
                    stateDesc = "Power Adapter"
                } else {
                    stateDesc = "On Battery"
                }

                return BatteryMetrics(
                    percent: pct,
                    isCharging: isCharging,
                    isPluggedIn: isPluggedIn,
                    timeRemainingMinutes: timeRemaining,
                    powerDrawWatts: powerWatts,
                    healthPercent: smartHealth,
                    stateDescription: stateDesc,
                    cycleCount: cycleCount,
                    adapterWatts: smartAdapterWatts,
                    adapterName: smartAdapterName
                )
            }
        }

        return BatteryMetrics(
            percent: 100.0,
            isCharging: false,
            isPluggedIn: true,
            timeRemainingMinutes: nil,
            powerDrawWatts: smartPowerWatts > 0 ? smartPowerWatts : 15.0,
            healthPercent: smartHealth,
            stateDescription: "Power Adapter",
            cycleCount: cycleCount,
            adapterWatts: smartAdapterWatts,
            adapterName: smartAdapterName
        )
    }
}
