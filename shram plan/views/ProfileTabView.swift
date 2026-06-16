import SwiftUI

struct ProfileTabView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userName") var userName: String = "Your Name"
    @AppStorage("userEmail") var userEmail: String = "your.email@example.com"
    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill"
    @AppStorage("customAvatarData") var customAvatarData: Data = Data()
    @AppStorage("isProUser") var isProUser: Bool = false

    @State private var showImagePicker = false
    @State private var showSubscriptionPaywall = false
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Spacer(minLength: 4)
                        AvatarView(iconName: avatarIcon, customData: customAvatarData, size: 90)
                            .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 4)
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Text("Change Avatar")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }

                Section("Personal Information") {
                    if isEditing {
                        HStack {
                            Text("Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            TextField("Name", text: $editedName)
                                .font(.system(size: 15, weight: .medium))
                        }
                        
                        HStack {
                            Text("Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            TextField("Email", text: $editedEmail)
                                .font(.system(size: 15, weight: .medium))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    } else {
                        LabeledContent {
                            Text(userName)
                                .font(.system(size: 15, weight: .medium))
                        } label: {
                            Text("Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        LabeledContent {
                            Text(userEmail)
                                .font(.system(size: 15, weight: .medium))
                        } label: {
                            Text("Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        if isEditing {
                            Button {
                                userName = editedName
                                userEmail = editedEmail
                                isEditing = false
                            } label: {
                                Text("Save Changes")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            Button {
                                isEditing = false
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                editedName = userName
                                editedEmail = userEmail
                                isEditing = true
                            } label: {
                                Text("Edit Profile Details")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Subscription") {
                    HStack(spacing: 12) {
                        Image(systemName: isProUser ? "crown.fill" : "crown")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isProUser ? .yellow : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isProUser ? "Pro Active" : "Free Tier")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text(isProUser ? "All features unlocked" : "Upgrade for premium tools")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showSubscriptionPaywall = true
                        } label: {
                            Text(isProUser ? "Manage" : "Upgrade")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(isProUser ? Color.secondary : Color.blue)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("About") {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shram Plan")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        withAnimation {
                            isLoggedIn = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImageData: $customAvatarData, selectedIcon: $avatarIcon)
            }
            .sheet(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(isPresented: $showSubscriptionPaywall)
            }
        }
    }
}

struct AvatarView: View {
    var iconName: String
    var customData: Data
    var size: CGFloat

    var body: some View {
        Group {
            if !customData.isEmpty {
                #if os(macOS)
                if let nsImage = NSImage(data: customData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.blue)
                        .frame(width: size, height: size)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                #else
                if let uiImage = UIImage(data: customData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.blue)
                        .frame(width: size, height: size)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                #endif
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.blue)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }
        }
    }
}

struct ImagePicker: View {
    @Binding var selectedImageData: Data
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Avatar Selection")
                    .font(.headline)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(avatarIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                selectedImageData = Data()
                                dismiss()
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 70, height: 70)
                                    .background(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                Button("Remove Custom Photo") {
                    selectedImageData = Data()
                    selectedIcon = "person.crop.circle.fill"
                    dismiss()
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private let avatarIcons = [
    "person.crop.circle.fill", "heart.fill", "star.fill", "bolt.fill",
    "leaf.fill", "flame.fill", "diamond.fill", "crown.fill",
    "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
    "gamecontroller.fill", "paintbrush.fill", "camera.fill", "music.note"
]
