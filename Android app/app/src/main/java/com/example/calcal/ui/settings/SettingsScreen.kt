package com.example.calcal.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onBack: () -> Unit = {}, viewModel: SettingsViewModel = hiltViewModel()) {
    val calorieGoal by viewModel.calorieGoal.collectAsState()
    val proteinGoal by viewModel.proteinGoal.collectAsState()
    val carbsGoal by viewModel.carbsGoal.collectAsState()
    val fatGoal by viewModel.fatGoal.collectAsState()
    val healthConnectEnabled by viewModel.healthConnectEnabled.collectAsState()
    val goalExplanation by viewModel.goalExplanation.collectAsState()
    val modelName by viewModel.modelName.collectAsState()
    val openRouterApiKey by viewModel.openRouterApiKey.collectAsState()
    val serperApiKey by viewModel.serperApiKey.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            SectionHeader("Daily Goals")
            GoalField("Calories (kcal)", calorieGoal) { viewModel.setCalorieGoal(it) }
            GoalField("Protein (g)", proteinGoal) { viewModel.setProteinGoal(it) }
            GoalField("Carbohydrates (g)", carbsGoal) { viewModel.setCarbsGoal(it) }
            GoalField("Fat (g)", fatGoal) { viewModel.setFatGoal(it) }

            Spacer(Modifier.height(8.dp))
            SectionHeader("AI Model")
            ModelField("OpenRouter Model", modelName) { viewModel.setModelName(it) }

            Spacer(Modifier.height(8.dp))
            SectionHeader("OpenRouter API Key")
            ApiKeyField("API Key", openRouterApiKey) { viewModel.setOpenRouterApiKey(it) }
            Text(
                "Get your free key at openrouter.ai/keys — the free tier is sufficient for normal app usage.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 4.dp)
            )

            Spacer(Modifier.height(8.dp))
            SectionHeader("Serper API Key")
            ApiKeyField("API Key", serperApiKey) { viewModel.setSerperApiKey(it) }
            Text(
                "Get your free key at serper.dev — 2,500 free searches/month, enough for everyday use.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 4.dp)
            )

            Spacer(Modifier.height(8.dp))
            SectionHeader("Integrations")
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                elevation = CardDefaults.cardElevation(0.dp)
            ) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text("Health Connect", style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium))
                        Text("Sync nutrition data", style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Switch(checked = healthConnectEnabled, onCheckedChange = { viewModel.setHealthConnectEnabled(it) })
                }
            }

            if (goalExplanation.isNotBlank()) {
                Spacer(Modifier.height(8.dp))
                SectionHeader("Your Goal Plan")
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    elevation = CardDefaults.cardElevation(0.dp)
                ) {
                    Text(goalExplanation, Modifier.padding(16.dp), style = MaterialTheme.typography.bodySmall)
                }
            }

            Spacer(Modifier.height(16.dp))
            Text(
                "CalCal for Android",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
            Spacer(Modifier.height(8.dp))
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 4.dp, vertical = 4.dp)
    )
}

@Composable
private fun GoalField(label: String, value: Double, onSave: (Double) -> Unit) {
    var text by remember(value) { mutableStateOf(value.toInt().toString()) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            label = { Text(label) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                focusedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            ),
            trailingIcon = {
                TextButton(onClick = { text.toDoubleOrNull()?.let { onSave(it) } }) { Text("Save") }
            }
        )
    }
}

@Composable
private fun ModelField(label: String, value: String, onSave: (String) -> Unit) {
    var text by remember(value) { mutableStateOf(value) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            label = { Text(label) },
            placeholder = { Text("e.g. google/gemini-flash-1.5") },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
            singleLine = true,
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                focusedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            ),
            trailingIcon = {
                TextButton(onClick = { if (text.isNotBlank()) onSave(text.trim()) }) { Text("Save") }
            }
        )
    }
}

@Composable
private fun ApiKeyField(label: String, value: String, onSave: (String) -> Unit) {
    var text by remember(value) { mutableStateOf(value) }
    var visible by remember { mutableStateOf(false) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            label = { Text(label) },
            placeholder = { Text("sk-or-...") },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
            singleLine = true,
            visualTransformation = if (visible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                focusedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            ),
            trailingIcon = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = { visible = !visible }) {
                        Icon(
                            if (visible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                            contentDescription = if (visible) "Hide key" else "Show key"
                        )
                    }
                    TextButton(onClick = { if (text.isNotBlank()) onSave(text.trim()) }) { Text("Save") }
                }
            }
        )
    }
}
