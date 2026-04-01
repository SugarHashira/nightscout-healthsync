import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: SyncViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    if viewModel.isSyncing {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Syncing...")
                        }
                    } else if let lastSync = viewModel.lastSyncDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Sync")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(lastSync, style: .relative)
                            Text(lastSync, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Never synced")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.syncNow()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                    }
                    .disabled(viewModel.isSyncing || !viewModel.isConfigured)
                }
                
                if let result = viewModel.syncResult {
                    Section("Last Sync Result") {
                        HStack {
                            Text("Treatments")
                            Spacer()
                            Text("\(result.treatmentsSynced)/\(result.treatmentsProcessed)")
                        }
                        HStack {
                            Text("Glucose Readings")
                            Spacer()
                            Text("\(result.glucoseSynced)/\(result.glucoseProcessed)")
                        }
                        if !result.errors.isEmpty {
                            ForEach(result.errors, id: \.self) { error in
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Configuration") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Nightscout Settings", systemImage: "gear")
                    }
                    NavigationLink(destination: LogsView()) {
                        Label("Sync Logs", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            .navigationTitle("Nightscout Sync")
        }
        .task {
            await viewModel.loadSettings()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: SyncViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var testingConnection = false
    @State private var connectionTestResult: Bool?
    @State private var showingHealthKitAlert = false
    @State private var showingSaved = false

    var body: some View {
        Form {
            Section("Nightscout") {
                TextField("Nightscout URL", text: $viewModel.nightscoutURL)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                
                SecureField("API Secret", text: $viewModel.nightscoutSecret)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                Button(action: {
                    Task {
                        testingConnection = true
                        connectionTestResult = await viewModel.testConnection()
                        testingConnection = false
                    }
                }) {
                    HStack {
                        if testingConnection {
                            ProgressView()
                        } else {
                            Text("Test Connection")
                        }
                    }
                }
                .disabled(viewModel.nightscoutURL.isEmpty || viewModel.nightscoutSecret.isEmpty)
                
                if let result = connectionTestResult {
                    Text(result ? "Connection successful!" : "Connection failed")
                        .foregroundColor(result ? .green : .red)
                }
            }
            
            Section("Apple Health") {
                Button("Request HealthKit Authorization") {
                    Task {
                        await viewModel.requestHealthKitAuthorization()
                        showingHealthKitAlert = true
                    }
                }
            }
            
            Section("Sync Options") {
                Picker("Glucose Unit", selection: $viewModel.selectedGlucoseUnit) {
                    Text("mg/dL").tag(GlucoseUnit.mgdl)
                    Text("mmol/L").tag(GlucoseUnit.mmol)
                }

                Toggle("Sync Glucose Readings", isOn: $viewModel.syncGlucose)
                Toggle("Sync Insulin", isOn: $viewModel.syncInsulin)
                Toggle("Sync Carbs", isOn: $viewModel.syncCarbs)
            }

            Section("Background Sync") {
                Toggle("Auto-sync in background", isOn: $viewModel.autoSyncEnabled)

                if viewModel.autoSyncEnabled {
                    Picker("Sync every", selection: $viewModel.backgroundSyncInterval) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                }
            }
            
            Section {
                Button("Save Settings") {
                    Task {
                        await viewModel.saveSettings()
                        showingSaved = true
                        try? await Task.sleep(for: .seconds(1))
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Settings")
        .overlay(alignment: .bottom) {
            if showingSaved {
                Label("Settings saved", systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.green, in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingSaved)
        .alert("HealthKit", isPresented: $showingHealthKitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Authorization requested. Please allow access to Health data in Settings.")
        }
    }
}

struct LogsView: View {
    @EnvironmentObject var viewModel: SyncViewModel

    var body: some View {
        Group {
            if viewModel.syncLogs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Logs Yet")
                        .font(.headline)
                    Text("Sync logs will appear here after your first sync.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                List(viewModel.syncLogs) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.date, style: .date)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(log.date, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 16) {
                            Label("\(log.glucoseSynced) glucose", systemImage: "drop.fill")
                                .foregroundStyle(.red)
                            Label("\(log.insulinSynced) insulin", systemImage: "syringe.fill")
                                .foregroundStyle(.blue)
                            Label("\(log.carbsSynced) carbs", systemImage: "fork.knife")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption)

                        if log.hasErrors {
                            ForEach(log.errors, id: \.self) { error in
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Sync Logs")
    }
}
