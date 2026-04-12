package com.example.calcal.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.QueryStats
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(val route: String) {
    object Tracker : Screen("tracker")
    object Statistics : Screen("statistics")
    object Streak : Screen("streak")
    object Settings : Screen("settings")
    object Onboarding : Screen("onboarding")
    object Camera : Screen("camera")
    object FoodItemDetail : Screen("food_item_detail/{itemId}") {
        fun createRoute(itemId: String) = "food_item_detail/$itemId"
    }
}

data class BottomNavItem(
    val screen: Screen,
    val label: String,
    val icon: ImageVector
)

val bottomNavItems = listOf(
    BottomNavItem(Screen.Tracker, "Tracker", Icons.Default.Home),
    BottomNavItem(Screen.Statistics, "Stats", Icons.Default.QueryStats),
    BottomNavItem(Screen.Streak, "Streak", Icons.Default.Whatshot),
    BottomNavItem(Screen.Settings, "Settings", Icons.Default.Settings)
)
