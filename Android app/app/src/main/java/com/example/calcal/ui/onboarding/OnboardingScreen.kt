package com.example.calcal.ui.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.calcal.domain.util.CalorieCalculator

@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val weightKg by viewModel.weightKg.collectAsState()
    val heightCm by viewModel.heightCm.collectAsState()
    val age by viewModel.age.collectAsState()
    val gender by viewModel.gender.collectAsState()
    val activityLevel by viewModel.activityLevel.collectAsState()
    val goalText by viewModel.goalText.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("Welcome to CalCal", style = MaterialTheme.typography.headlineMedium)
        Text("Let's set up your profile", style = MaterialTheme.typography.bodyLarge)

        OutlinedTextField(
            value = weightKg.toString(),
            onValueChange = { it.toDoubleOrNull()?.let { v -> viewModel.weightKg.value = v } },
            label = { Text("Weight (kg)") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = heightCm.toString(),
            onValueChange = { it.toDoubleOrNull()?.let { v -> viewModel.heightCm.value = v } },
            label = { Text("Height (cm)") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = age.toString(),
            onValueChange = { it.toIntOrNull()?.let { v -> viewModel.age.value = v } },
            label = { Text("Age") },
            modifier = Modifier.fillMaxWidth()
        )

        // Gender selector
        Text("Gender", style = MaterialTheme.typography.labelLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            CalorieCalculator.Gender.entries.forEach { g ->
                FilterChip(
                    selected = gender == g,
                    onClick = { viewModel.gender.value = g },
                    label = { Text(g.name.lowercase().replaceFirstChar { it.uppercase() }) }
                )
            }
        }

        // Activity level selector
        Text("Activity Level", style = MaterialTheme.typography.labelLarge)
        CalorieCalculator.ActivityLevel.entries.forEach { level ->
            FilterChip(
                selected = activityLevel == level,
                onClick = { viewModel.activityLevel.value = level },
                label = { Text(level.displayName()) },
                modifier = Modifier.fillMaxWidth()
            )
        }

        OutlinedTextField(
            value = goalText,
            onValueChange = { viewModel.goalText.value = it },
            label = { Text("Your goal (optional)") },
            placeholder = { Text("e.g. lose 5kg, build muscle...") },
            modifier = Modifier.fillMaxWidth()
        )

        Button(
            onClick = { viewModel.complete(onComplete) },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                Spacer(Modifier.width(8.dp))
                Text("Calculating your goals...")
            } else {
                Text("Get Started")
            }
        }
    }
}
