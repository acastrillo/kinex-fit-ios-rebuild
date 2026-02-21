import SwiftUI
import AuthenticationServices

/// The sign-in screen shown when the user is not authenticated.
struct AuthView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: AuthViewModel?

    var body: some View {
        Group {
            if let viewModel {
                AuthContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(
                    authService: AuthService(apiClient: environment.apiClient),
                    environment: environment
                )
            }
        }
    }
}

// MARK: - Auth Content

private struct AuthContent: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Logo & Title
            VStack(spacing: AppTheme.spacingMD) {
                Image(systemName: AppTheme.Icon.workout)
                    .font(.system(size: 72))
                    .foregroundStyle(.accent)

                Text("Kinex Fit")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your fitness companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, AppTheme.spacingXXL)

            Spacer()

            // Sign-In Buttons
            VStack(spacing: AppTheme.spacingMD) {
                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    // Handled by AppleSignInManager via AuthViewModel
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(AppTheme.cornerRadiusSM)
                .overlay {
                    // Overlay a tap gesture to use our own flow
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await viewModel.signInWithApple() }
                        }
                }

                // Sign in with Google
                ProviderButton(
                    title: "Sign in with Google",
                    systemImage: "g.circle.fill",
                    backgroundColor: .white,
                    foregroundColor: .black
                ) {
                    Task { await viewModel.signInWithGoogle() }
                }

                // Sign in with Facebook
                ProviderButton(
                    title: "Sign in with Facebook",
                    systemImage: "f.circle.fill",
                    backgroundColor: Color(red: 0.23, green: 0.35, blue: 0.60),
                    foregroundColor: .white
                ) {
                    Task { await viewModel.signInWithFacebook() }
                }

                // Sign in with Email
                ProviderButton(
                    title: "Sign in with Email",
                    systemImage: "envelope.fill",
                    backgroundColor: .accent,
                    foregroundColor: .white
                ) {
                    viewModel.showEmailSignIn = true
                }

                #if DEBUG
                // Dev Mode Bypass
                Button {
                    Task { await viewModel.signInDevMode() }
                } label: {
                    Text("Dev Mode (Skip Auth)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppTheme.spacingSM)
                }
                #endif
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, AppTheme.spacingXL)

            Spacer()
                .frame(height: AppTheme.spacingXXL)
        }
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .alert(
            "Sign In Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ),
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) { viewModel.error = nil }
        } message: { error in
            if let description = error.errorDescription {
                Text(description)
            }
        }
        .sheet(isPresented: $viewModel.showEmailSignIn) {
            EmailSignInSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Provider Button

private struct ProviderButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingMD) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(AppTheme.cornerRadiusSM)
        }
    }
}

// MARK: - Email Sign-In Sheet

private struct EmailSignInSheet: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacingLG) {
                Text("Sign in with Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, AppTheme.spacingLG)

                VStack(spacing: AppTheme.spacingMD) {
                    TextField("Email", text: $viewModel.emailText)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)

                    SecureField("Password", text: $viewModel.passwordText)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                }
                .padding(.horizontal, AppTheme.spacingLG)

                Button {
                    Task {
                        await viewModel.signInWithEmail()
                        if viewModel.error == nil {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.emailText.isBlank || viewModel.passwordText.isEmpty || viewModel.isLoading)
                .padding(.horizontal, AppTheme.spacingLG)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                focusedField = .email
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .withPreviewEnvironment()
}
