//
//  Dashboard.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import SwiftUI

struct Dashboard: View {
    @StateObject var model: DashboardModel = DashboardModel()
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack {
                    Panel {
                        if let actives = model.activeChazaraPoints {
                            List {
                                ForEach(actives) { point in
                                    PointCell(point)
                                }
                            }
                        }
                    }
                }
                VStack {
                Panel {
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
                Spacer()
            }
        }
        }
        .navigationTitle("Dashboard")
    }
    
    struct Panel<Content: View>: View {
        var content: Content
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            ZStack {
                AngularGradient(gradient: Gradient(stops: [Gradient.Stop(color: Color(hue: 0.4572532378047346, saturation: 0.18340398030108718, brightness: 0.8, opacity: 1.0), location: 0.0), Gradient.Stop(color: Color(hue: 0.45274495503988615, saturation: 0.36811144955186964, brightness: 0.8, opacity: 1.0), location: 0.35195647019606374)]), center: UnitPoint.topLeading, angle: .radians(0.0))
                    .cornerRadius(UI.cornerRadius)
                    .padding()
                    .shadow(radius: UI.shadowRadius)
                content
                    .padding()
            }
        }
    }
    
    struct PointCell: View {
        @ObservedObject var point: ChazaraPoint
        @State var dueDate: Date?
        
        init(_ point: ChazaraPoint) {
            self.point = point
            
            let dueDateTask = Task { [ self ] in
                self.dueDate = await point.getDueDate()
            }
        }
        
        var body: some View {
            if let sectionName = Storage.shared.getSection(sectionId: point.sectionId)?.name {
                VStack {
                    HStack {
                        Text(sectionName)
                            .font(Font.title)
                        
                        Spacer()
                        
                        if let dueDate = dueDate {
                            Text(dueDate.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: .omitted))
                        }
                    }
                }
            }
        }
    }
}

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
