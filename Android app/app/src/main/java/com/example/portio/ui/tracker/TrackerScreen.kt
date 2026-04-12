package com.example.portio.ui.tracker

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.portio.domain.model.FoodItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrackerScreen(
    onOpenCamera: () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenStreak: () -> Unit,
    onOpenStats: () -> Unit,
    onOpenDetail: (String) -> Unit,
    viewModel: TrackerViewModel = hiltViewModel()
) {
    val items by viewModel.todayItems.collectAsState()
    val calorieGoal by viewModel.calorieGoal.collectAsState()
    val proteinGoal by viewModel.proteinGoal.collectAsState()
    val carbsGoal by viewModel.carbsGoal.collectAsState()
    val fatGoal by viewModel.fatGoal.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()

    val totalCalories = items.filter { !it.isProcessing }.sumOf { it.calories }
    val totalProtein = items.filter { !it.isProcessing }.sumOf { it.protein }
    val totalCarbs = items.filter { !it.isProcessing }.sumOf { it.carbs }
    val totalFat = items.filter { !it.isProcessing }.sumOf { it.fat }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Portio", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                },
                actions = {
                    IconButton(onClick = onOpenStreak) {
                        Icon(
                            Icons.Default.Whatshot,
                            contentDescription = "Streak",
                            tint = if (items.isNotEmpty()) MaterialTheme.colorScheme.primary
                                   else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        bottomBar = {
            ChatInput(
                onSubmit = { query -> viewModel.addItem(query) },
                onCameraClick = onOpenCamera
            )
        },
        snackbarHost = {
            errorMessage?.let { msg ->
                Snackbar(
                    modifier = Modifier.padding(16.dp),
                    action = { TextButton(onClick = { viewModel.clearError() }) { Text("OK") } }
                ) { Text(msg) }
            }
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(innerPadding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Totals card — clickable to open stats
            item {
                TotalsCard(
                    calories = totalCalories, calorieGoal = calorieGoal,
                    protein = totalProtein, proteinGoal = proteinGoal,
                    carbs = totalCarbs, carbsGoal = carbsGoal,
                    fat = totalFat, fatGoal = fatGoal,
                    onClick = onOpenStats
                )
            }

            // Section header
            if (items.isNotEmpty()) {
                item {
                    Text(
                        "Today's Entries",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 4.dp)
                    )
                }
            }

            items(items, key = { it.id }) { item ->
                FoodItemRow(
                    item = item,
                    onClick = { if (!item.isProcessing) onOpenDetail(item.id) },
                    onDelete = { viewModel.deleteItem(item) }
                )
            }
        }
    }
}
