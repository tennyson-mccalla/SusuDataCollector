import AppKit
import SwiftUI

// A custom button style for a modern, clean look.
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// The view for displaying a single script, now with a modern design.
struct ScriptView: View {
    let script: String
    let onSave: (String) -> Void
    let isSaving: Bool

    @State private var transcript: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Script display area
            Text(script)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(30)
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

            // Transcript input field
            TextField("Paste or type your transcript here...", text: $transcript, onCommit: saveAndTriggerNext)
                .textFieldStyle(.plain)
                .font(.body)
                .padding()
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(12)
                .focused($isTextFieldFocused)
                
            // Save button
            Button("Save & Next", action: saveAndTriggerNext)
                .buttonStyle(ModernButtonStyle())
                .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
        }
        .onAppear {
            // Automatically focus the text field when the view appears.
            // A slight delay ensures the view is fully rendered.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    private func saveAndTriggerNext() {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscript.isEmpty else { return }
        onSave(trimmedTranscript)
    }
}

// The main container view, orchestrating the app's flow.
struct ContentView: View {
    @State private var scriptIndex: Int = 0
    @State private var scripts: [String] = []
    @State private var isShowingCompletionAlert = false
    @State private var isSaving = false

    var body: some View {
        ZStack {
            // Background color for the entire view
            Color(NSColor.underPageBackgroundColor).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                if scripts.isEmpty {
                    Text("Loading Scripts...")
                        .font(.headline)
                } else if scriptIndex < scripts.count {
                    // Header with title and countdown
                    VStack {
                        Text("Susu Data Collector")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Scripts Remaining: \(scripts.count - scriptIndex)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // The ScriptView is embedded here. The transition adds a fade-in/out effect.
                    ScriptView(script: scripts[scriptIndex], onSave: save, isSaving: isSaving)
                        .id(scriptIndex)
                        .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                    
                } else {
                    Text("All scripts completed. Thank you!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(30)
        }
        .onAppear(perform: loadScripts)
        .alert(isPresented: $isShowingCompletionAlert) {
            Alert(
                title: Text("Submission Ready"),
                message: Text("The dataset.txt file is ready to be sent. The Mail app will now open with a pre-filled email. Please click 'Send' to complete the process."),
                dismissButton: .default(Text("OK"), action: {
                    emailDataset()
                })
            )
        }
    }

    func loadScripts() {
        if let filepath = Bundle.main.path(forResource: "scripts", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                scripts = contents.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            } catch {
                print("Error loading scripts: \(error)")
            }
        }
    }

    func save(transcript: String) {
        guard !isSaving else { return }
        guard scriptIndex < scripts.count else {
            print("Error: Attempted to save with an invalid script index.")
            return
        }
        
        isSaving = true
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
            }
            catch {
                print("Error saving dataset: \(error)")
            }
        }
        
        if scriptIndex == scripts.count - 1 {
            isShowingCompletionAlert = true
        }
        
        scriptIndex += 1
        
        DispatchQueue.main.async {
            isSaving = false
        }
    }
    
    func getSystemInfo() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let cpuModel = String(cString: machine)
        
        return """
        --- System Information ---
        macOS Version: \(osVersion)
        Processor: \(cpuModel)
        --------------------------
        """
    }
    
    func emailDataset() {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = dir.appendingPathComponent("dataset.txt")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Dataset file not found.")
            return
        }

        let service = NSSharingService(named: .composeEmail)!
        service.recipients = ["tennyson.mccalla@superbuilders.school"]
        service.subject = "Susu Data Collector Submission"
        
        let systemInfo = getSystemInfo()
        let body = """
        Thank you for your contribution! Please find the dataset.txt file attached.
        
        \(systemInfo)
        """
        
        service.perform(withItems: [body, fileURL])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
