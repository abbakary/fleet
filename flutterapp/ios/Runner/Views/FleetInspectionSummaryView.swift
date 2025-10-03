import SwiftUI

struct FleetInspectionSummaryView: View {
    private let modules: [SummaryItem] = [
        SummaryItem(title: "Admin Portal (Django)", detail: "Browser-based control center for staff to onboard customers, register vehicles, assign inspectors, and review complete inspection data."),
        SummaryItem(title: "Inspector Mobile App (Flutter)", detail: "Offline-capable field tool enabling inspectors to execute standardized inspections, capture mandatory photo evidence, and register new fleet vehicles."),
        SummaryItem(title: "Customer Mobile Experience (Flutter)", detail: "User-friendly access for customers to review vehicle health trends, inspection histories, and prioritized action items."),
        SummaryItem(title: "Unified Django REST API", detail: "Single source of truth powering all modules, ensuring consistent data governance and role-based access controls.")
    ]

    private let workflowSteps: [SummaryItem] = [
        SummaryItem(title: "Customer Onboarding", detail: "Administrators create customer accounts, configure fleets, and issue secure credentials."),
        SummaryItem(title: "Inspection Execution", detail: "Inspectors execute guided checklists across 13 categories, flag findings, and attach photographic evidence."),
        SummaryItem(title: "Report Generation", detail: "System compiles technical and customer-friendly reports with role-specific detail levels and timestamped metadata."),
        SummaryItem(title: "Continuous Visibility", detail: "Customers monitor fleet condition trends, while administrators orchestrate corrective actions and scheduling.")
    ]

    private let differentiators: [String] = [
        "Evidence-driven inspections with mandatory photo capture for critical findings.",
        "Dynamic checklists tuned to vehicle type, ensuring no inspection gaps.",
        "Offline-first mobile workflow with automatic synchronization on network restoration.",
        "Role-aware experiences that surface the right level of detail to every stakeholder.",
        "Centralized data architecture preventing silos and ensuring auditable history."
    ]

    private let inspectionCategories: [String] = [
        "Pre-Trip Documentation",
        "Exterior & Structure",
        "Tires, Wheels, Axles",
        "Braking System",
        "Suspension & Steering",
        "Engine & Powertrain",
        "Electrical & Lighting",
        "Cabin & Interior",
        "Coupling & Connections",
        "Trailer-Specific Equipment",
        "Safety Equipment",
        "Operational Tests",
        "Under-Vehicle Inspection"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SummaryIntroView()
                    SummaryCardView(title: "Tri-Module Platform", caption: "Coordinated experiences for administrators, inspectors, and customers.") {
                        ForEach(modules) { item in
                            SummaryDetailRow(item: item)
                        }
                    }
                    SummaryCardView(title: "Inspection Lifecycle", caption: "Guided process from onboarding to insights.") {
                        ForEach(workflowSteps) { item in
                            SummaryDetailRow(item: item)
                        }
                    }
                    SummaryCardView(title: "Inspection Categories", caption: "Thirteen comprehensive checkpoints ensure full coverage.") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(inspectionCategories, id: \.self) { category in
                                SummaryBullet(text: category)
                            }
                        }
                    }
                    SummaryCardView(title: "Strategic Differentiators", caption: "Design choices that elevate operational reliability.") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(differentiators, id: \.self) { differentiator in
                                SummaryBullet(text: differentiator)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(red: 0.95, green: 0.97, blue: 1.0))
            .scrollIndicators(.hidden)
            .navigationTitle("Fleet Inspection Summary")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct SummaryIntroView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fleet Inspection Management System")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.07, green: 0.15, blue: 0.25))
            Text("A centralized ecosystem aligning administrative oversight, field inspections, and customer transparency. The system orchestrates every inspection touchpoint through a unified backend, delivering auditable, evidence-rich reports.")
                .font(.body)
                .foregroundColor(Color(red: 0.18, green: 0.24, blue: 0.32))
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Core Purpose")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.07, green: 0.15, blue: 0.25))
                        SummaryBullet(text: "Equip inspectors with guided, photo-backed workflows to capture vehicle condition accurately.")
                        SummaryBullet(text: "Empower administrators to coordinate fleets, inspectors, and reporting in one portal.")
                        SummaryBullet(text: "Deliver customers the clarity and accountability they need to manage maintenance decisions.")
                    }
                    .padding(20)
                )
        }
    }
}

private struct SummaryCardView<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.07, green: 0.15, blue: 0.25))
                Text(caption)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.35, green: 0.41, blue: 0.49))
            }
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
}

private struct SummaryDetailRow: View {
    let item: SummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.11, green: 0.2, blue: 0.34))
            Text(item.detail)
                .font(.footnote)
                .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.4))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.9, green: 0.93, blue: 0.97))
                .frame(height: 1)
                .padding(.top, 36)
            , alignment: .bottom
        )
    }
}

private struct SummaryBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(red: 0.17, green: 0.47, blue: 0.93))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(.footnote)
                .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.4))
                .multilineTextAlignment(.leading)
        }
    }
}

private struct SummaryItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

#Preview {
    FleetInspectionSummaryView()
}
