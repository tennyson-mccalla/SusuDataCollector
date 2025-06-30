import SwiftUI

// This new view manages the state for a single script and its transcript.
// When a new script is shown, a new instance of this view is created,
// guaranteeing the transcript field is reset.
struct ScriptView: View {
    let script: String
    let onSave: (String) -> Void // Closure to pass the transcript back to the parent

    @State private var transcript: String = ""

    var body: some View {
        VStack {
            Text(script)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)
                .border(Color.gray, width: 1)

            TextField("Paste transcript here", text: $transcript, onCommit: {
                saveAndTriggerNext()
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save & Next") {
                saveAndTriggerNext()
            }
            .padding()
        }
    }

    private func saveAndTriggerNext() {
        // Ensure the transcript is not just empty spaces
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else {
            return
        }
        // Call the closure provided by the parent view to save the data
        onSave(trimmedTranscript)
    }
}

// The main ContentView is now simpler. It just manages the list of scripts
// and which one is currently active.
struct ContentView: View {
    @State private var scriptIndex: Int = 0
    @State private var scripts: [String] = []

    var body: some View {
        VStack {
            if scripts.isEmpty {
                Text("Loading scripts...")
            } else if scriptIndex < scripts.count {
                // Display the countdown
                Text("Scripts remaining: \(scripts.count - scriptIndex)")
                    .font(.headline)
                    .padding()
                
                // Create a ScriptView for the current script.
                // When `scriptIndex` changes, this view is recreated from scratch
                // because its ID is changing. This is the key to the fix.
                ScriptView(script: scripts[scriptIndex], onSave: save)
                    .id(scriptIndex)
                
            } else {
                Text("All scripts completed!")
                    .font(.headline)
                    .padding()
            }
        }
        .onAppear(perform: loadScripts)
        .padding()
    }

    func loadScripts() {
        if let filepath = Bundle.main.path(forResource: "scripts", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                // Filter out any empty lines from the scripts file
                scripts = contents.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            } catch {
                // We'll keep this one log for genuine errors.
                print("Error loading scripts: \(error)")
            }
        }
    }

    // This function is now only responsible for saving the data and advancing the index.
    func save(transcript: String) {
        let script = scripts[scriptIndex]
        let datasetLine = "\(transcript)<|>\(script)\n"

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("dataset.txt")
            
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(datasetLine.data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try datasetLine.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            } catch {
                // We'll keep this one log for genuine errors.
                print("Error saving dataset: \(error)")
            }
        }

        // Advancing the index is now the single source of truth for moving to the next script.
        scriptIndex += 1
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}