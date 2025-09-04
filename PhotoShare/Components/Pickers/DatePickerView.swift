import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text("선택된 날짜")
                .font(.subheadline)
                .fontWeight(.medium)
.foregroundStyle(theme.secondaryGradient)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingDatePicker.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(selectedDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
.foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.98, blue: 0.95),
                                    Color(red: 0.92, green: 0.96, blue: 0.98)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.1, green: 0.6, blue: 0.8).opacity(0.1), radius: 3, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 1.0, blue: 0.95),
                            Color(red: 0.95, green: 0.98, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

// Overlay Calendar Picker with Natural Animations
struct OverlayDatePicker: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    
    @State private var backgroundOpacity: Double = 0.0
    @State private var calendarScale: Double = 0.85
    @State private var calendarOpacity: Double = 0.0
    @State private var calendarOffset: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Enhanced Background Blur with Better Dimming
            LinearGradient(
                colors: [
                    Color.black.opacity(backgroundOpacity * 0.25),
                    Color.black.opacity(backgroundOpacity * 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture {
                dismissCalendar()
            }
            
            // Calendar picker with natural entrance
            VStack(spacing: 24) {
                HStack {
                    Text("날짜 선택")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    Button(action: dismissCalendar) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .scaleEffect(0.9)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                DatePicker("날짜 선택",
                          selection: $selectedDate,
                          displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .colorScheme(.light)
                    .accentColor(Color(red: 0.2, green: 0.7, blue: 0.4))
                    .onChange(of: selectedDate) { _, newDate in
                        // Auto-close with gentle delay and pass selected date
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dismissCalendar()
                            onDateSelected(newDate)
                        }
                    }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 1.0, blue: 0.97),
                                Color(red: 0.96, green: 0.99, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 24,
                        x: 0,
                        y: 12
                    )
                    .shadow(
                        color: Color.black.opacity(0.06),
                        radius: 48,
                        x: 0,
                        y: 24
                    )
            )
            .padding(.horizontal, 24)
            .scaleEffect(calendarScale)
            .opacity(calendarOpacity)
            .offset(y: calendarOffset)
        }
        .onAppear {
            presentCalendar()
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                presentCalendar()
            } else {
                hideCalendar()
            }
        }
    }
    
    private func presentCalendar() {
        // 동시 시작으로 더 자연스러운 등장
        withAnimation(.easeOut(duration: 0.35)) {
            backgroundOpacity = 1.0
        }
        
        // 부드러운 스프링 애니메이션으로 자연스러운 바운스
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
            calendarScale = 1.0
            calendarOpacity = 1.0
            calendarOffset = 0
        }
    }
    
    private func hideCalendar() {
        // 대칭적인 타이밍으로 일관성 향상
        withAnimation(.easeInOut(duration: 0.3)) {
            calendarScale = 0.9
            calendarOpacity = 0.0
            calendarOffset = 15
        }
        
        withAnimation(.easeOut(duration: 0.35)) {
            backgroundOpacity = 0.0
        }
    }
    
    private func dismissCalendar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

#Preview {
    DatePickerView(selectedDate: .constant(Date()), showingDatePicker: .constant(false))
        .padding()
}