package com.example.portio.ui.detail

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.portio.domain.model.FoodItem
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FoodItemDetailScreenWrapper(
    itemId: String,
    onBack: () -> Unit,
    viewModel: FoodItemDetailViewModel = hiltViewModel()
) {
    val item by viewModel.getItem(itemId).collectAsState(initial = null)
    item?.let {
        FoodItemDetailScreen(item = it, onSave = { updated ->
            viewModel.save(updated)
            onBack()
        }, onDelete = {
            viewModel.delete(it)
            onBack()
        }, onDismiss = onBack)
    } ?: Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FoodItemDetailScreen(
    item: FoodItem,
    onSave: (FoodItem) -> Unit,
    onDelete: () -> Unit = {},
    onDismiss: () -> Unit
) {
    val focusManager = LocalFocusManager.current
    var weightText by remember { mutableStateOf(item.weightGrams.roundToInt().toString()) }
    var editingNutrients by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            icon = { Icon(Icons.Default.Delete, contentDescription = null) },
            title = { Text("Delete entry?") },
            text = { Text(item.cleanFoodName.ifBlank { item.name }) },
            confirmButton = {
                TextButton(onClick = { showDeleteDialog = false; onDelete() }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") }
            }
        )
    }

    // Nutrient edit state
    var caloriesText by remember { mutableStateOf(item.calories.roundToInt().toString()) }
    var proteinText by remember { mutableStateOf(item.protein.roundToInt().toString()) }
    var carbsText by remember { mutableStateOf(item.carbs.roundToInt().toString()) }
    var fatText by remember { mutableStateOf(item.fat.roundToInt().toString()) }

    val weight = weightText.toDoubleOrNull() ?: item.weightGrams
    val ratio = if (item.weightGrams > 0) weight / item.weightGrams else 1.0

    // When not editing nutrients manually, scale from weight
    val displayCalories = if (editingNutrients) caloriesText.toDoubleOrNull() ?: 0.0 else item.calories * ratio
    val displayProtein = if (editingNutrients) proteinText.toDoubleOrNull() ?: 0.0 else item.protein * ratio
    val displayCarbs = if (editingNutrients) carbsText.toDoubleOrNull() ?: 0.0 else item.carbs * ratio
    val displayFat = if (editingNutrients) fatText.toDoubleOrNull() ?: 0.0 else item.fat * ratio

    // Auto-save when weight changes
    fun autoSave() {
        val newWeight = weightText.toDoubleOrNull() ?: return
        val saved = item.copy(
            weightGrams = newWeight,
            calories = displayCalories,
            protein = displayProtein,
            carbs = displayCarbs,
            fat = displayFat
        )
        onSave(saved)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(item.cleanFoodName.ifBlank { item.name }) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showDeleteDialog = true }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.error)
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Entry info
            SectionCard {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    InfoRow("Original Query", item.name)
                    InfoRow("Identified As", item.identifiedFood.ifBlank { item.name })
                }
            }

            // Source badges
            if (item.isSearchGrounded) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    item.dataSource?.let { source ->
                        if (source.contains("OFF")) SourceBadge("Open Food Facts", Color(0xFF43A047))
                        if (source.contains("Google")) SourceBadge("Google Search", Color(0xFF1E88E5))
                    }
                }
            }

            // Weight field — auto-saves on Done
            OutlinedTextField(
                value = weightText,
                onValueChange = { weightText = it },
                label = { Text("Weight (g)") },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(onDone = {
                    focusManager.clearFocus()
                    autoSave()
                }),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            // Nutrition facts card
            NutritionFactsCard(
                calories = displayCalories,
                protein = displayProtein,
                carbs = displayCarbs,
                fat = displayFat,
                caloriesPer100g = item.caloriesPer100g,
                proteinPer100g = item.proteinPer100g,
                carbsPer100g = item.carbsPer100g,
                fatPer100g = item.fatPer100g,
                servingSize = "${weight.roundToInt()}g"
            )

            // Edit nutrients button
            OutlinedButton(
                onClick = {
                    if (!editingNutrients) {
                        // Populate edit fields with current scaled values
                        caloriesText = displayCalories.roundToInt().toString()
                        proteinText = displayProtein.roundToInt().toString()
                        carbsText = displayCarbs.roundToInt().toString()
                        fatText = displayFat.roundToInt().toString()
                    }
                    editingNutrients = !editingNutrients
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text(if (editingNutrients) "Done Editing" else "Edit Nutrients")
            }

            // Nutrient editors
            if (editingNutrients) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                    elevation = CardDefaults.cardElevation(0.dp)
                ) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Edit Nutrients", style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold))
                        NutrientEditField("Calories (kcal)", caloriesText) { caloriesText = it }
                        NutrientEditField("Protein (g)", proteinText) { proteinText = it }
                        NutrientEditField("Carbs (g)", carbsText) { carbsText = it }
                        NutrientEditField("Fat (g)", fatText) { fatText = it }
                        Button(
                            onClick = {
                                val saved = item.copy(
                                    weightGrams = weight,
                                    calories = caloriesText.toDoubleOrNull() ?: item.calories,
                                    protein = proteinText.toDoubleOrNull() ?: item.protein,
                                    carbs = carbsText.toDoubleOrNull() ?: item.carbs,
                                    fat = fatText.toDoubleOrNull() ?: item.fat
                                )
                                onSave(saved)
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) { Text("Save Changes") }
                    }
                }
            }

            // Search steps
            item.searchSteps.forEach { step ->
                SearchDetailCard(
                    step = step,
                    isOFF = item.dataSource?.contains("OFF") == true
                )
            }

            // Delete button
            Button(
                onClick = { showDeleteDialog = true },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
            ) {
                Icon(Icons.Default.Delete, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Delete entry")
            }
        }
    }
}

@Composable
private fun NutrientEditField(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        shape = RoundedCornerShape(10.dp)
    )
}

@Composable
private fun SectionCard(content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Box(Modifier.padding(16.dp)) { content() }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
            modifier = Modifier.padding(start = 8.dp))
    }
}

@Composable
private fun SourceBadge(label: String, color: Color) {
    Surface(shape = RoundedCornerShape(50), color = color.copy(alpha = 0.12f)) {
        Row(
            Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = color, modifier = Modifier.size(12.dp))
            Text(label, style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = color)
        }
    }
}

@Composable
fun NutritionFactsCard(
    calories: Double, protein: Double, carbs: Double, fat: Double,
    caloriesPer100g: Double, proteinPer100g: Double, carbsPer100g: Double, fatPer100g: Double,
    servingSize: String = ""
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(16.dp)) {
            Text("Nutrition Facts", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.ExtraBold))
            if (servingSize.isNotBlank()) {
                Text("Serving size: $servingSize", style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            HorizontalDivider(Modifier.padding(vertical = 8.dp), thickness = 2.dp)
            NutrientFactRow("Calories", calories, caloriesPer100g, "kcal", isMain = true)
            HorizontalDivider(Modifier.padding(vertical = 4.dp))
            NutrientFactRow("Protein", protein, proteinPer100g, "g")
            HorizontalDivider(Modifier.padding(vertical = 4.dp))
            NutrientFactRow("Carbohydrates", carbs, carbsPer100g, "g")
            HorizontalDivider(Modifier.padding(vertical = 4.dp))
            NutrientFactRow("Fat", fat, fatPer100g, "g")
        }
    }
}

@Composable
private fun NutrientFactRow(label: String, value: Double, per100g: Double, unit: String, isMain: Boolean = false) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = if (isMain) MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold)
                            else MaterialTheme.typography.bodyMedium)
        Column(horizontalAlignment = Alignment.End) {
            Text("${value.roundToInt()} $unit",
                style = if (isMain) MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold)
                        else MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold))
            Text("${per100g.roundToInt()} $unit / 100g",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun SearchDetailCard(step: com.example.portio.domain.model.SearchStep, isOFF: Boolean = false) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            // Header row: query pill + optional OFF badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(shape = RoundedCornerShape(50), color = Color(0xFF1E88E5).copy(alpha = 0.12f)) {
                    Row(
                        Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(Icons.Default.Search, contentDescription = null,
                            tint = Color(0xFF1E88E5), modifier = Modifier.size(12.dp))
                        Text(step.query, style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                            color = Color(0xFF1E88E5), maxLines = 1)
                    }
                }
                if (isOFF) {
                    Surface(shape = RoundedCornerShape(50), color = Color(0xFF43A047).copy(alpha = 0.12f)) {
                        Row(
                            Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(3.dp)
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null,
                                tint = Color(0xFF43A047), modifier = Modifier.size(10.dp))
                            Text("OFF", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.ExtraBold),
                                color = Color(0xFF43A047), fontSize = 9.sp)
                        }
                    }
                }
            }

            // Answer box
            step.answerBox?.let { answer ->
                Card(shape = RoundedCornerShape(10.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.6f)),
                    elevation = CardDefaults.cardElevation(0.dp)) {
                    Column(Modifier.padding(10.dp)) {
                        Text("AI SUMMARY", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.ExtraBold),
                            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 8.sp)
                        Spacer(Modifier.height(2.dp))
                        Text(answer, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }

            // Search results
            step.results.forEach { result ->
                Card(shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.5f)),
                    elevation = CardDefaults.cardElevation(0.dp)) {
                    Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(result.title, style = MaterialTheme.typography.labelMedium.copy(
                            fontWeight = FontWeight.Bold, color = Color(0xFF1E88E5)), maxLines = 1)
                        Text(result.snippet, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 2)
                    }
                }
            }
        }
    }
}
