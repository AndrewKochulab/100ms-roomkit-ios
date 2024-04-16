//
//  HMSTranscriptView.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 4/2/24.
//

import SwiftUI
import HMSRoomModels

struct HMSTranscriptView: View {
    
    enum Activity {
        case none, speaking
    }
    
    @State var activity: Activity = .speaking
    @State var expiredTranscriptionLength = 0
    
    @State var hideTasks = [Task<(), any Error>]()
    var hideTranscriptTask: Task<(), any Error> {
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            activity = .none
            expiredTranscriptionLength = roomModel.transcript.count
        }
    }
    
    @EnvironmentObject var roomModel: HMSRoomModel
    
    var body: some View {
        VStack {
            if activity == .speaking {
                let freshTranscriptLength = max(roomModel.transcript.count - expiredTranscriptionLength, 0)
                let transcript = roomModel.transcript.suffix(min(freshTranscriptLength, 400))
                
                let speakerLabel: String = {
                    // if current transcript lacks speaker label then show recent speaker label ourselves
                    if transcript.first == "\n" {
                        return ""
                    }
                    else {
                        let lastSpeakerName = lastTranscriptLabel(transcript: String(roomModel.transcript.prefix(expiredTranscriptionLength)))
                        return "\(lastSpeakerName): "
                    }
                }()
                
                // Don't show empty transcript
                if !transcript.isEmpty {
                    VStack {
                        Text(speakerLabel + transcript)
                            .lineLimit(nil)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxHeight: 90, alignment: .bottom)
                    .fixedSize(horizontal: false, vertical: true)
                    .clipped()
                    .padding(12)
                    .background(.backgroundDim, cornerRadius: 8, opacity: 0.64)
                    .padding(8)
                }
            }
        }
        .onChange(of: roomModel.transcript) { transcript in
            // Cancel hiding transcript if there is new transcription activity
            hideTasks.forEach{$0.cancel()}
            hideTasks.removeAll()
            activity = .speaking
            hideTasks.append(hideTranscriptTask)
        }
    }
    
    public func lastTranscriptLabel(transcript: String) -> String {
        let lines = transcript.split(separator: "\n")
        guard let lastLine = lines.last else { return "" }
        let components = lastLine.split(separator: ":", maxSplits: 1)
        guard let lastSpeaker = components.first else { return "" }
        return String(lastSpeaker).trimmingCharacters(in: .whitespaces)
    }
}

struct HMSTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
#if Preview
        HMSTranscriptView()
            .environmentObject(HMSRoomModel.dummyRoom(2))
            .environmentObject(HMSUITheme())
#endif
    }
}
