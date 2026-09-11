//
//  ContentView.swift
//  brokenithm-swiftui
//
//  Created by Owen Cramer on 8/27/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @State var connection: Listener? = nil
    @State var drawerOpen: Bool = false
    @State var sheetShowing: Bool = false
    @AppStorage("airOn") var airOn: Bool = false
    @AppStorage("airHeightOption") var airHeightOption: String = "Normal"
    let airOptions: [String] = ["Small", "Normal", "Large"]
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.black)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    if connection != nil {
                        Text(connection!.status)
                            .padding(.horizontal)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    
                    Menu {
                        Toggle(isOn: $airOn.animation(.bouncy(duration: 0.3, extraBounce: 0.2))) {
                            Text("Air Input")
                        }
                        Picker("Air Height", selection: $airHeightOption.animation(.bouncy(duration: 0.3, extraBounce: 0.2))) {
                            ForEach(airOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                        Button("Restart Connection", systemImage: "arrow.clockwise") {
                            connection?.restart()
                        }
                        Button("Test Button", systemImage: "wrench.and.screwdriver") {
                            connection?.triggerTest()
                        }
                        Button("Service Button", systemImage: "gearshape") {
                            connection?.triggerService()
                        }
                        Button("Tap Card", systemImage: "person.text.rectangle") {
                            connection?.tapCard()
                        }
                        Button("Insert Coin", systemImage: "dollarsign.circle") {
                            connection?.insertCoin()
                        }
                        Button("About", systemImage: "info.circle") {
                            sheetShowing.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down.circle")
                            .font(.title2)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .foregroundStyle(.white)
                    }
                }
                .background(Gradient(colors: [connection?.status == "Connected" ? .green.mix(with: .white, by: 0.2).opacity(0.7) : .red.opacity(0.7), .black.opacity(0.05)]))
                Rectangle()
                    .foregroundStyle(.ultraThinMaterial)
                    .frame(height: 3)
                    .ignoresSafeArea()
                InputBoardView(connection: $connection, airOn: $airOn, airOption: $airHeightOption)
            }
        }
        .ignoresSafeArea(edges: [.bottom])
        .defersSystemGestures(on: .all)
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                connection?.restart()
            }
        }
        .onChange(of: airOn) {
            connection?.enableAir(enabled: airOn)
        }
        .onAppear {
            if connection == nil {
                let newConnection = Listener()
                newConnection.airOn = airOn
                connection = newConnection
            } else {
                connection?.airOn = airOn
            }
        }
        .sheet(isPresented: $sheetShowing, content: { AboutView(isPresented: $sheetShowing).presentationDragIndicator(.visible) })
        
    }
}

#Preview {
    ContentView()
}
