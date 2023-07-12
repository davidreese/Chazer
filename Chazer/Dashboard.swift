//
//  Dashboard.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import SwiftUI

struct Dashboard: View {
    @ObservedObject var model: DashboardModel = DashboardModel()
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack {
                    
                    
                    Panel(gradient: AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 1.0, saturation: 0.6854498070406627, brightness: 0.8, opacity: 1.0), location: 0.19659705528846155), Gradient.Stop(color: Color(hue: 0.5677681428840362, saturation: 1.0, brightness: 0.8, opacity: 1.0), location: 0.7326472355769231)]), center: UnitPoint.topLeading, angle: .radians(5.007772431542131))) {
                        VStack {
                            HStack {
                                Text("Late")
                                    .font(.title)
                                    .bold()
                                Spacer()
                            }
                            
                            Divider()
                            
                            if let lateChazaraPoints = model.lateChazaraPoints {
                                VStack {
                                    ForEach(lateChazaraPoints.sorted(by: { lhs, rhs in
                                        if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                                            return lhsDate < rhsDate
                                        } else {
                                            //                                    this isn't really supposed to occur
                                            return true
                                        }
                                    })) { point in
                                        DashboardPointBar(chazaraPoint: point)
                                            .background(BackgroundBlurView(style: .regular)
                                                .cornerRadius(UI.cornerRadius))
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    Panel(gradient: AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.5453719173569278, saturation: 1.0, brightness: 0.8, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 0.950868905308735, saturation: 1.0, brightness: 0.8, opacity: 1.0), location: 0.6383263221153845)]), center: UnitPoint.topLeading, angle: .radians(6.2744539114252245)), content:  {
                        VStack {
                            HStack {
                                Text("Active")
                                    .font(.title)
                                    .bold()
                                Spacer()
                            }
                            
                            Divider()
                            
                            if let activeChazaraPoints = model.activeChazaraPoints {
                                VStack {
                                    ForEach(activeChazaraPoints.sorted(by: { lhs, rhs in
                                        if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                                            return lhsDate < rhsDate
                                        } else {
                                            //                                    this isn't really supposed to occur
                                            return true
                                        }
                                    })) { point in
                                        DashboardPointBar(chazaraPoint: point)
                                            .background(BackgroundBlurView(style: .regular)
                                                .cornerRadius(UI.cornerRadius))
                                    }
                                }
                            }
                        }
                        .padding()
                    })
                    .padding()
                }
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
                    }.frame(width: 300, height: 300)
                        .padding()
                    Spacer()
                }
            }
        }
        .navigationTitle("Dashboard")
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
                    Spacer()
                }
                    .frame(width: 150)
                
                    Divider()
                HStack {
                    Text(model.point?.fetchSection()?.name ?? "nil")
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Text(model.text ?? "time does not exist")
                        .onAppear {
                            Task {
                                await update()
                            }
                        }
                    Spacer()
                }
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
