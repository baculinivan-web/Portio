package com.example.portio.ui.tracker

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

@Composable
fun TotalsCard(
    calories: Double, calorieGoal: Double,
    protein: Double, proteinGoal: Double,
    carbs: Double, carbsGoal: Double,
    fat: Double, fatGoal: Double,
    onClick: () -> Unit = {}
) {
    val progress = if (calorieGoal > 0) (calories / calorieGoal).coerceIn(0.0, 1.0).toFloat() else 0f
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = spring(dampingRatio = 0.8f),
        label = "calorie_progress"
    )

    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Calorie count
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = calories.roundToInt().toString(),
                    style = MaterialTheme.typography.displaySmall.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 36.sp
                    )
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    text = "/ ${calorieGoal.roundToInt()} kcal",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Progress bar
            LinearProgressIndicator(
                progress = { animatedProgress },
                modifier = Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(3.dp)),
                color = MaterialTheme.colorScheme.onSurface,
                trackColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
            )

            // Macros row
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                MacroItem("Protein", protein, proteinGoal)
                MacroItem("Carbs", carbs, carbsGoal)
                MacroItem("Fat", fat, fatGoal)
            }
        }
    }
}

@Composable
private fun MacroItem(label: String, value: Double, goal: Double) {
    Column(horizontalAlignment = Alignment.Start) {
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(
            "${value.roundToInt()} / ${goal.roundToInt()} g",
            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold)
        )
    }
}
