package com.example.calcal

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.calcal.data.preferences.UserSettings
import com.example.calcal.ui.navigation.Screen
import com.example.calcal.ui.onboarding.OnboardingScreen
import com.example.calcal.ui.settings.SettingsScreen
import com.example.calcal.ui.statistics.StatisticsScreen
import com.example.calcal.ui.streak.StreakScreen
import com.example.calcal.ui.theme.CalCalTheme
import com.example.calcal.ui.tracker.TrackerScreen
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var userSettings: UserSettings

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val hasOnboarded = runBlocking { userSettings.hasCompletedOnboarding.first() }

        setContent {
            CalCalTheme {
                val navController = rememberNavController()

                NavHost(
                    navController = navController,
                    startDestination = if (hasOnboarded) Screen.Tracker.route else Screen.Onboarding.route
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
                        com.example.calcal.ui.camera.CameraScreen(
                            onPhotoTaken = { navController.popBackStack() },
                            onDismiss = { navController.popBackStack() }
                        )
                    }
                    composable(Screen.FoodItemDetail.route) { backStackEntry ->
                        val itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
                        com.example.calcal.ui.detail.FoodItemDetailScreenWrapper(
                            itemId = itemId,
                            onBack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}
