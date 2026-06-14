package com.example.portio

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.lifecycle.lifecycleScope
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.portio.data.repository.FoodRepository
import com.example.portio.data.preferences.UserSettings
import com.example.portio.ui.navigation.Screen
import com.example.portio.ui.onboarding.OnboardingScreen
import com.example.portio.ui.settings.SettingsScreen
import com.example.portio.ui.statistics.StatisticsScreen
import com.example.portio.ui.streak.StreakScreen
import com.example.portio.ui.theme.PortioTheme
import com.example.portio.ui.tracker.TrackerScreen
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var userSettings: UserSettings
    @Inject lateinit var foodRepository: FoodRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            PortioTheme {
                val navController = rememberNavController()
                val scope = rememberCoroutineScope()
                var startupState by remember { mutableStateOf<StartupState?>(null) }
                var blockRunPromptDismissed by remember { mutableStateOf(false) }

                LaunchedEffect(Unit) {
                    combine(
                        userSettings.hasCompletedOnboarding,
                        userSettings.hasShownBlockRunPrompt
                    ) { hasOnboarded, hasShownPrompt ->
                        StartupState(hasOnboarded, hasShownPrompt)
                    }.collect { startupState = it }
                }

                val state = startupState
                if (state == null) {
                    Surface(Modifier.fillMaxSize()) {
                        Box(contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                    return@PortioTheme
                }

                val showBlockRunDialog = state.hasOnboarded &&
                    !state.hasShownBlockRunPrompt &&
                    !blockRunPromptDismissed

                if (showBlockRunDialog) {
                    AlertDialog(
                        onDismissRequest = {
                            blockRunPromptDismissed = true
                            scope.launch { userSettings.setHasShownBlockRunPrompt(true) }
                        },
                        title = { Text("Try BlockRun AI?") },
                        text = { Text("BlockRun AI uses free local models via cloud gateway. This is a beta feature for autonomous AI agents. No local proxy required.") },
                        confirmButton = {
                            TextButton(onClick = {
                                scope.launch {
                                    userSettings.setHasShownBlockRunPrompt(true)
                                }
                                navController.navigate(Screen.Settings.route)
                                blockRunPromptDismissed = true
                            }) {
                                Text("Configure")
                            }
                        },
                        dismissButton = {
                            TextButton(onClick = {
                                scope.launch { userSettings.setHasShownBlockRunPrompt(true) }
                                blockRunPromptDismissed = true
                            }) {
                                Text("Maybe Later")
                            }
                        }
                    )
                }

                NavHost(
                    navController = navController,
                    startDestination = if (state.hasOnboarded) Screen.Tracker.route else Screen.Onboarding.route
                ) {
                    composable(Screen.Onboarding.route) {
                        OnboardingScreen(onComplete = {
                            navController.navigate(Screen.Tracker.route) {
                                popUpTo(Screen.Onboarding.route) { inclusive = true }
                            }
                        })
                    }
                    composable(Screen.Tracker.route) {
                        TrackerScreen(
                            onOpenCamera = { navController.navigate(Screen.Camera.route) },
                            onOpenSettings = { navController.navigate(Screen.Settings.route) },
                            onOpenStreak = { navController.navigate(Screen.Streak.route) },
                            onOpenStats = { navController.navigate(Screen.Statistics.route) },
                            onOpenDetail = { itemId ->
                                navController.navigate(Screen.FoodItemDetail.createRoute(itemId))
                            }
                        )
                    }
                    composable(Screen.Statistics.route) {
                        StatisticsScreen(onBack = { navController.popBackStack() })
                    }
                    composable(Screen.Streak.route) {
                        StreakScreen(onBack = { navController.popBackStack() })
                    }
                    composable(Screen.Settings.route) {
                        SettingsScreen(onBack = { navController.popBackStack() })
                    }
                    composable(Screen.Camera.route) {
                        com.example.portio.ui.camera.CameraScreen(
                            onPhotoTaken = { bytes ->
                                lifecycleScope.launch {
                                    foodRepository.addItem("Photo food", images = listOf(bytes))
                                }
                                navController.popBackStack()
                            },
                            onDismiss = { navController.popBackStack() }
                        )
                    }
                    composable(Screen.FoodItemDetail.route) { backStackEntry ->
                        val itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
                        com.example.portio.ui.detail.FoodItemDetailScreenWrapper(
                            itemId = itemId,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}

private data class StartupState(
    val hasOnboarded: Boolean,
    val hasShownBlockRunPrompt: Boolean
)
