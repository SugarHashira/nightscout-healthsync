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
    @State private var testingConnection = false
    @State private var connectionTestResult: Bool?
    @State private var showingHealthKitAlert = false
    
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
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Settings")
        .alert("HealthKit", isPresented: $showingHealthKitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Authorization requested. Please allow access to Health data in Settings.")
        }
    }
}
