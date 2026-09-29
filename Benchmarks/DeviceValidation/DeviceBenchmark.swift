import Foundation
import UIKit

/// One fresh application process per engine/trial. C++ is development-only.
@MainActor
enum DeviceBenchmark {
    private static func execute(engine: String, workload: String, mode: String, iterations: Int32, size: Int32) throws -> Any {
        let text: String
        if engine == "cpp" {
            guard let output = yoga_reference_run(workload, mode, iterations, size) else {
                throw CocoaError(.coderInvalidValue)
            }
            text = String(cString: output)
            free(output)
        } else {
            text = try runNativeBenchmark(arguments: ["native", workload, mode, String(iterations), String(size), "1"])
        }
        return try JSONSerialization.jsonObject(with: Data(text.utf8))
    }

    static func runIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard let start = args.firstIndex(of: "--benchmark"), args.count >= start + 6 else { return }
        let engine = args[start + 1]
        let workload = args[start + 2]
        let mode = args[start + 3]
        guard ["swift", "cpp"].contains(engine), let size = Int32(args[start + 5]), size > 0 else { exit(2) }
        do {
            let thermalBefore = ProcessInfo.processInfo.thermalState.rawValue
            let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            let result: Any
            if mode == "suite" {
                let counts = try JSONDecoder().decode([String: Int32].self, from: Data(args[start + 4].utf8))
                var rows: [Any] = []
                for name in ["rebuild", "relayout", "mutation", "cached", "memory"] {
                    guard let count = counts[name], count > 0 else { exit(2) }
                    rows.append(try execute(engine: engine, workload: workload, mode: name, iterations: count, size: size))
                }
                result = rows
            } else {
                guard let count = Int32(args[start + 4]), count > 0 else { exit(2) }
                result = try execute(engine: engine, workload: workload, mode: mode, iterations: count, size: size)
            }
            let object: [String: Any] = [
                "result": result, "device": UIDevice.current.model,
                "os": UIDevice.current.systemVersion,
                "thermal_before": thermalBefore,
                "thermal_after": ProcessInfo.processInfo.thermalState.rawValue,
                "low_power_mode": lowPower
            ]
            let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            print("YOGA_RESULT=" + String(decoding: data, as: UTF8.self))
            fflush(nil)
            exit(0)
        } catch {
            print("YOGA_ERROR=\(error)")
            exit(1)
        }
    }
}
