// VolumeAction.swift — GestureKit/Actions
// Controls system volume using CoreAudio's AudioHardware API.
// Adjusts the default output device's volume in real time.

import Foundation
import CoreAudio
import AudioToolbox

public enum VolumeAction {

    // MARK: – Volume adjustment

    /// Change the system output volume by `delta` (range: -1.0 to +1.0).
    /// A delta of 0.0625 corresponds to one "notch" on the volume slider (1/16).
    public static func adjustVolume(delta: Float) {
        guard let deviceID = defaultOutputDevice() else { return }

        var currentVolume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)

        var address = AudioObjectPropertyAddress(
            // kAudioHardwareServiceDeviceProperty_VirtualMasterVolume was renamed in macOS 10.9.
            // Use kAudioHardwareServiceDeviceProperty_VirtualMainVolume instead.
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Read current volume.
        let getStatus = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &currentVolume)
        guard getStatus == noErr else { return }

        // Clamp new volume to [0, 1].
        var newVolume = min(max(currentVolume + delta, 0), 1)

        // Write new volume.
        let setStatus = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &newVolume)
        if setStatus != noErr {
            print("[VolumeAction] Failed to set volume: \(setStatus)")
        }
    }

    // MARK: – Mute toggle

    public static func toggleMute() {
        guard let deviceID = defaultOutputDevice() else { return }

        var isMuted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isMuted)
        var newMuted: UInt32 = isMuted == 0 ? 1 : 0
        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &newMuted)
    }

    // MARK: – Default output device

    private static func defaultOutputDevice() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )

        return status == noErr && deviceID != kAudioObjectUnknown ? deviceID : nil
    }
}
