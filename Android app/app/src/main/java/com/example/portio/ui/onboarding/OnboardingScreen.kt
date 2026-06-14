package com.example.portio.ui.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.portio.data.preferences.UserSettings
import com.example.portio.domain.util.CalorieCalculator

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val gender by viewModel.gender.collectAsState()
    val activityLevel by viewModel.activityLevel.collectAsState()
    val goalText by viewModel.goalText.collectAsState()
    val openRouterApiKey by viewModel.openRouterApiKey.collectAsState()
    val serperApiKey by viewModel.serperApiKey.collectAsState()
    val error by viewModel.error.collectAsState()
    val llmProvider by viewModel.llmProvider.collectAsState()
    val modelName by viewModel.modelName.collectAsState()
    val customApiBaseUrl by viewModel.customApiBaseUrl.collectAsState()
    val blockRunWalletId by viewModel.blockRunWalletId.collectAsState()
    val blockRunProxyUrl by viewModel.blockRunProxyUrl.collectAsState()
    var apiKeyVisible by remember { mutableStateOf(false) }
    var serperKeyVisible by remember { mutableStateOf(false) }
    var walletKeyVisible by remember { mutableStateOf(false) }
    var weightText by remember { mutableStateOf("") }
    var heightText by remember { mutableStateOf("") }
    var ageText by remember { mutableStateOf("") }
    var showProviderMenu by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("Welcome to Portio", style = MaterialTheme.typography.headlineMedium)
        Text("Let's set up your profile", style = MaterialTheme.typography.bodyLarge)

        error?.let {
            Text(
                it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium
            )
        }

        OutlinedTextField(
            value = weightText,
            onValueChange = { weightText = it; it.toDoubleOrNull()?.let { v -> viewModel.weightKg.value = v } },
            label = { Text("Weight (kg)") },
            placeholder = { Text("e.g. 70") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
        )
        OutlinedTextField(
            value = heightText,
            onValueChange = { heightText = it; it.toDoubleOrNull()?.let { v -> viewModel.heightCm.value = v } },
            label = { Text("Height (cm)") },
            placeholder = { Text("e.g. 175") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
        )
        OutlinedTextField(
            value = ageText,
            onValueChange = { ageText = it; it.toIntOrNull()?.let { v -> viewModel.age.value = v } },
            label = { Text("Age") },
            placeholder = { Text("e.g. 28") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
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

        Text("AI Provider", style = MaterialTheme.typography.labelLarge)
        Box {
            OutlinedCard(onClick = { showProviderMenu = true }, modifier = Modifier.fillMaxWidth()) {
                Row(
                    Modifier.fillMaxWidth().padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(llmProvider.displayName)
                    Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                }
            }
            DropdownMenu(expanded = showProviderMenu, onDismissRequest = { showProviderMenu = false }) {
                UserSettings.LLMProvider.entries.forEach { provider ->
                    DropdownMenuItem(
                        text = { Text(provider.displayName) },
                        onClick = {
                            viewModel.llmProvider.value = provider
                            showProviderMenu = false
                        }
                    )
                }
            }
        }

        when (llmProvider) {
            UserSettings.LLMProvider.OPEN_ROUTER -> {
                OutlinedTextField(
                    value = openRouterApiKey,
                    onValueChange = { viewModel.openRouterApiKey.value = it },
                    label = { Text("OpenRouter API Key") },
                    placeholder = { Text("sk-or-...") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    visualTransformation = if (apiKeyVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    trailingIcon = {
                        IconButton(onClick = { apiKeyVisible = !apiKeyVisible }) {
                            Icon(
                                if (apiKeyVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = if (apiKeyVisible) "Hide key" else "Show key"
                            )
                        }
                    },
                    supportingText = { Text("Free key at openrouter.ai/keys") }
                )
                OutlinedTextField(
                    value = modelName,
                    onValueChange = { viewModel.modelName.value = it },
                    label = { Text("Model") },
                    placeholder = { Text("e.g. google/gemini-flash-1.5") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
            UserSettings.LLMProvider.CUSTOM -> {
                OutlinedTextField(
                    value = customApiBaseUrl,
                    onValueChange = { viewModel.customApiBaseUrl.value = it },
                    label = { Text("Base URL") },
                    placeholder = { Text("https://api.openai.com/v1") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    supportingText = { Text("OpenAI-compatible endpoint; /chat/completions is appended automatically") }
                )
                OutlinedTextField(
                    value = openRouterApiKey,
                    onValueChange = { viewModel.openRouterApiKey.value = it },
                    label = { Text("API Key") },
                    placeholder = { Text("sk-...") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    visualTransformation = if (apiKeyVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    trailingIcon = {
                        IconButton(onClick = { apiKeyVisible = !apiKeyVisible }) {
                            Icon(
                                if (apiKeyVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = if (apiKeyVisible) "Hide key" else "Show key"
                            )
                        }
                    }
                )
                OutlinedTextField(
                    value = modelName,
                    onValueChange = { viewModel.modelName.value = it },
                    label = { Text("Model") },
                    placeholder = { Text("e.g. gpt-4o") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
            UserSettings.LLMProvider.BLOCKRUN -> {
                OutlinedTextField(
                    value = blockRunProxyUrl,
                    onValueChange = { viewModel.blockRunProxyUrl.value = it },
                    label = { Text("API Endpoint") },
                    placeholder = { Text("https://blockrun.ai/api/v1") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                OutlinedTextField(
                    value = blockRunWalletId,
                    onValueChange = { viewModel.blockRunWalletId.value = it },
                    label = { Text("Wallet Key / ID") },
                    placeholder = { Text("0x...") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    visualTransformation = if (walletKeyVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    trailingIcon = {
                        IconButton(onClick = { walletKeyVisible = !walletKeyVisible }) {
                            Icon(
                                if (walletKeyVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                contentDescription = if (walletKeyVisible) "Hide key" else "Show key"
                            )
                        }
                    }
                )
                OutlinedTextField(
                    value = modelName,
                    onValueChange = { viewModel.modelName.value = it },
                    label = { Text("Model") },
                    placeholder = { Text("nvidia/mistral-small-4-119b") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        }

        OutlinedTextField(
            value = serperApiKey,
            onValueChange = { viewModel.serperApiKey.value = it },
            label = { Text("Serper API Key") },
            placeholder = { Text("...") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            visualTransformation = if (serperKeyVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            trailingIcon = {
                IconButton(onClick = { serperKeyVisible = !serperKeyVisible }) {
                    Icon(
                        if (serperKeyVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (serperKeyVisible) "Hide key" else "Show key"
                    )
                }
            },
            supportingText = { Text("Free key at serper.dev — 2,500 free searches/month, enough for everyday use") }
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
