//
//  TabBarItem.swift
//  AuroraEditor
//
//  Created by Lukas Pistrol on 17.03.22.
//

import SwiftUI

struct TabBarItem: View {

    @Environment(\.isFullscreen)
    private var isFullscreen

    @Environment(\.controlActiveState)
    var activeState

    @Environment(\.colorScheme)
    var colorScheme

    @ObservedObject
    var workspace: WorkspaceDocument

    @StateObject
    var prefs: AppPreferencesModel = .shared

    @State
    var isHovering: Bool = false

    @State
    var isHoveringClose: Bool = false

    @State
    var isPressingClose: Bool = false

    @State
    var isAppeared: Bool = false

    @Binding
    private var expectedWidth: CGFloat

    var item: TabBarItemRepresentable

    var isTemporary: Bool

    var isActive: Bool {
        item.tabID == workspace.selectionState.selectedId
    }

    func switchAction() {
        // Only set the `selectedId` when they are not equal to avoid performance issue for now.
        if workspace.selectionState.selectedId != item.tabID {
            workspace.selectionState.selectedId = item.tabID
        }
    }

    func closeAction() {
        if prefs.preferences.general.tabBarStyle == .native {
            isAppeared = false
        }
        withAnimation(
            .easeOut(
                duration:
                    prefs.preferences.general.tabBarStyle == .native
                ? 0.15
                : 0.20
            )
        ) {
            workspace.closeTab(item: item.tabID)
        }
    }

    init(
        expectedWidth: Binding<CGFloat>,
        item: TabBarItemRepresentable,
        workspace: WorkspaceDocument
    ) {
        self._expectedWidth = expectedWidth
        self.item = item
        self.workspace = workspace
        self.isTemporary = workspace.selectionState.temporaryTab == item.tabID
    }

    @ViewBuilder
    var content: some View {
        HStack(spacing: 0.0) {
            TabDivider()
                .opacity(isActive && prefs.preferences.general.tabBarStyle == .xcode ? 0.0 : 1.0)
                .padding(.top, isActive && prefs.preferences.general.tabBarStyle == .native ? 1.22 : 0)
            // Tab content (icon and text).
            iconTextView
            .opacity(
                // Inactive states for tab bar item content.
                activeState != .inactive
                ? 1.0
                : (
                    isActive
                    ? (prefs.preferences.general.tabBarStyle == .xcode ? 0.6 : 0.35)
                    : (prefs.preferences.general.tabBarStyle == .xcode ? 0.4 : 0.55)
                )
            )
            TabDivider()
                .opacity(isActive && prefs.preferences.general.tabBarStyle == .xcode ? 0.0 : 1.0)
                .padding(.top, isActive && prefs.preferences.general.tabBarStyle == .native ? 1.22 : 0)
        }
        .overlay(alignment: .top) {
            // Only show NativeTabShadow when `tabBarStyle` is native and this tab is not active.
            TabBarTopDivider()
                .opacity(prefs.preferences.general.tabBarStyle == .native && !isActive ? 1 : 0)
        }
        .foregroundColor(
            isActive
            ? (
                prefs.preferences.general.tabBarStyle == .xcode && colorScheme != .dark
                ? Color(nsColor: .controlAccentColor)
                : .primary
            )
            : (
                prefs.preferences.general.tabBarStyle == .xcode
                ? .primary
                : .secondary
            )
        )
        .frame(maxHeight: .infinity) // To vertically max-out the parent (tab bar) area.
        .contentShape(Rectangle()) // Make entire area clickable.
        .onHover { hover in
            isHovering = hover
            DispatchQueue.main.async {
                if hover {
                    NSCursor.arrow.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }

    var body: some View {
        Button(
            action: switchAction,
            label: { content }
        )
        .buttonStyle(TabBarItemButtonStyle())
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    if isTemporary {
                        workspace.convertTemporaryTab()
                    }
                }
        )
        .background {
            if prefs.preferences.general.tabBarStyle == .xcode {
                ZStack {
                    // This layer of background is to hide dividers of other tab bar items
                    // because the original background above is translucent (by opacity).
                    TabBarXcodeBackground()
                    if isActive {
                        Color(nsColor: .controlAccentColor)
                            .saturation(
                                colorScheme == .dark
                                ? (activeState != .inactive ? 0.60 : 0.75)
                                : (activeState != .inactive ? 0.90 : 0.85)
                            )
                            .opacity(
                                colorScheme == .dark
                                ? (activeState != .inactive ? 0.50 : 0.35)
                                : (activeState != .inactive ? 0.18 : 0.12)
                            )
                            .hueRotation(.degrees(-5))
                    }
                }
                .animation(.easeInOut(duration: 0.08), value: isHovering)
            } else {
                if isFullscreen && isActive {
                    TabBarNativeActiveMaterial()
                } else {
                    TabBarNativeMaterial()
                }
                ZStack {
                    // Native inactive tab background dim.
                    TabBarNativeInactiveBackgroundColor()
                    // Native inactive tab hover state.
                    Color(nsColor: colorScheme == .dark ? .white : .black)
                        .opacity(isHovering ? (colorScheme == .dark ? 0.08 : 0.05) : 0.0)
                        .animation(.easeInOut(duration: 0.10), value: isHovering)
                }
                .padding(.horizontal, 1)
                .opacity(isActive ? 0 : 1)
            }
        }
        .padding(
            // This padding is to avoid background color overlapping with top divider.
            .top, prefs.preferences.general.tabBarStyle == .xcode ? 1 : 0
        )
        .offset(
            x: isAppeared || prefs.preferences.general.tabBarStyle == .native ? 0 : -14,
            y: 0
        )
        .opacity(isAppeared ? 1.0 : 0.0)
        .zIndex(isActive ? (prefs.preferences.general.tabBarStyle == .native ? -1 : 1) : 0)
        .frame(
            width: (
                // Constrain the width of tab bar item for native tab style only.
                prefs.preferences.general.tabBarStyle == .native
                ? max(expectedWidth.isFinite ? expectedWidth : 0, 0)
                : nil
            )
        )
        .onAppear {
            if (isTemporary && workspace.selectionState.previousTemporaryTab == nil)
                || !(isTemporary && workspace.selectionState.previousTemporaryTab != item.tabID) {
                withAnimation(
                    .easeOut(duration: prefs.preferences.general.tabBarStyle == .native ? 0.15 : 0.20)
                ) {
                    isAppeared = true
                }
            } else {
                withAnimation(.linear(duration: 0.0)) {
                    isAppeared = true
                }
            }
        }
        .id(item.tabID)
        .tabBarContextMenu(item: item, workspace: workspace, isTemporary: isTemporary)
    }
}
// swiftlint:enable type_body_length
