//
//  Dashboard.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import SwiftUI
import Foundation

struct Dashboard: View {
    @Environment(\.scenePhase) var scenePhase
    
    @ObservedObject var model: DashboardModel = DashboardModel()
    
//    @State var exportViewShowing = false
    @State var fileExporterShowing = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack {
                VStack {
                    Panel(gradient: AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.0, saturation: 0.47299451713102414, brightness: 0.9067559299698796, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 1.0, saturation: 0.19771860881024098, brightness: 0.8947812735316266, opacity: 1.0), location: 0.49006911057692304)]), center: UnitPoint.topLeading, angle: .radians(6.251897256168942))) {
                        VStack {
                            HStack {
                                Text("Late")
                                    .font(.title)
                                    .bold()
                                Spacer()
                                Text(model.lateChazaraPoints?.count.description ?? "")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Divider()
                            
                            if let lateChazaraPoints = model.lateChazaraPoints {
                                if !lateChazaraPoints.isEmpty {
                                    VStack {
                                        ForEach(lateChazaraPoints) { point in
                                            DashboardPointBar(chazaraPoint: point)
                                                .background(BackgroundBlurView(style: .regular)
                                                    .cornerRadius(UI.cornerRadius))
                                                .frame(maxHeight: 75)
                                        }
                                    }
                                } else {
                                    Text("You are not late on any chazaras.")
                                        .font(.title3)
                                        .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    Panel(gradient: AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.665665592055723, saturation: 0.1391160344503012, brightness: 0.9067559299698796, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 0.6813464796686748, saturation: 0.576671922063253, brightness: 0.8947812735316266, opacity: 1.0), location: 0.8050030048076923)]), center: UnitPoint.topLeading, angle: .radians(6.18344144834115)), content:  {
                        VStack {
                            HStack {
                                Text("Active")
                                    .font(.title)
                                    .bold()
                                Spacer()
                                Text(model.activeChazaraPoints?.count.description ?? "")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Divider()
                            
                            if let activeChazaraPoints = model.activeChazaraPoints {
                                if !activeChazaraPoints.isEmpty {
                                    VStack {
                                        ForEach(activeChazaraPoints) { point in
                                            DashboardPointBar(chazaraPoint: point)
                                                .background(BackgroundBlurView(style: .regular)
                                                    .cornerRadius(UI.cornerRadius))
                                                .frame(maxHeight: 75)
                                        }
                                    }
                                } else {
                                    Text("You have no assigned chazaras to be done at the moment.")
                                        .font(.title3)
                                        .padding()
                                }
                            }
                        }
                        .padding()
                    })
                    .padding()
                }
                /*
                VStack {
                    Panel(gradient: AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.25879200395331325, saturation: 0.872023249246988, brightness: 0.8, opacity: 1.0), location: 0.2376201923076922), Gradient.Stop(color: Color(hue: 0.5677681428840362, saturation: 1.0, brightness: 0.8, opacity: 1.0), location: 0.6892803485576923)]), center: UnitPoint.topLeading, angle: .radians(3.3970877559323203))) {
                        let now = Date.now
                        let calendar = Calendar.current
                        let month = calendar.component(.month, from: now)
                        if month <= 12 && month >= 1 {
                            let monthName = calendar.shortMonthSymbols[month - 1]
                            VStack {
                                Text("\(monthName) \(calendar.component(.day, from: now))")
                                    .font(.largeTitle)
                                    .bold()
                                Text(String(format: "%d", calendar.component(.year, from: now)))
                                    .font(.largeTitle)
                                    .bold()
                            }
                        } else {
                            Text("An error occured.")
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 300)
                        .padding()
                    Spacer()
                }
                 */
//                .padding(.bottom, 1)
            }
        }
//        .frame(minWidth: 1000)
//        .padding(.bottom, 1)
        .navigationTitle("Dashboard")
        .toolbar {
            if let pdf = model.pdf {
                ToolbarItem {
                    Menu {
                        ShareLink(item: pdf, preview: SharePreview("PDF"))
                        Button {
                            fileExporterShowing = true
                        } label: {
                                Text("Download")
                                Image(systemName: "arrow.down")
                        }
                    } label: {
                        Text("Export")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await model.updateDashboard()
            }
        }
        .fileExporter(isPresented: $fileExporterShowing, document: PDFDocumentForExport(pdf: self.model.pdf), contentType: .pdf, defaultFilename: model.pdfFilename, onCompletion: { result in
            if case .success(let url) = result {
                print("PDF exported successfully to: \(url)")
            } else if case .failure(let error) = result {
                print("Error exporting PDF: \(error)")
            }
        })
    }
    
    struct Panel<Content: View>: View {
        var content: Content
        var gradient: AngularGradient
        
        init(gradient: AngularGradient = AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.4572532378047346, saturation: 0.18340398030108718, brightness: 0.8, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 0.45274495503988615, saturation: 0.36811144955186964, brightness: 0.8, opacity: 1.0), location: 0.35195647019606374)]), center: UnitPoint.topLeading, angle: .radians(0.0)), @ViewBuilder content: @escaping () -> Content) {
            self.content = content()
            self.gradient = gradient
        }
        
        var body: some View {
            ZStack {
                gradient
                    .cornerRadius(UI.cornerRadius)
                    .shadow(radius: UI.shadowRadius)
                content
                    .padding()
            }
        }
    }
    
    /// A view used on the dashboard for a detailed presentation of a given ``ChazaraPoint``.
    struct DashboardPointBar: View {
        //TODO: Evaluate if this should be changed to its own model
        @StateObject var model: StatusBoxModel
        
        init(chazaraPoint: ChazaraPoint) {
            self._model = StateObject(wrappedValue: StatusBoxModel(point: chazaraPoint))
        }
        
        var body: some View {
            let hasNotes = !(model.point?.notes?.isEmpty ?? true)
            HStack {
                HStack {
                    Text(model.point?.getLimud()?.name ?? "nil")
                        .bold()
//                        .accessibility(label: Text(model.point?.getLimud()?.name ?? "nil"))
                    Spacer()
                }
                    .frame(width: 150)
                
                    Divider()
                HStack {
                    Text(model.point?.fetchSection()?.name ?? "nil")
                    Spacer()
                }.frame(minWidth: 60, maxWidth: 150)
                
                Spacer()
                
                Divider()
            HStack {
                Text(model.point?.fetchSC()?.name ?? "nil")
                Spacer()
            }.frame(minWidth: 150)
            
            Spacer()
                
                Divider()
                
                HStack {
                    Text(model.text ?? "nil")
                        .onAppear {
                            Task {
                                await update()
                            }
                        }
                    Spacer()
                }.frame(minWidth: 100)
                Spacer()
            }
            .font(.title3)
            .padding()
            .overlay {
                VStack {
                    if hasNotes {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(.yellow)
                                .frame(width: 8, height: 8)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                        Spacer()
                    }
                }
            }
//            .background(RoundedRectangle(cornerRadius: 3).fill(Color.white))
        }
        
        private func update() async {
            model.updateText()
        }
    }
}

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
