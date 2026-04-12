package com.example.portio.ui.statistics

import androidx.compose.animation.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberColumnCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.columnSeries
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatisticsScreen(onBack: () -> Unit = {}, viewModel: StatisticsViewModel = hiltViewModel()) {
    val todayItems by viewModel.todayItems.collectAsState()
    val last7Days by viewModel.last7Days.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }

    val totalCalories = todayItems.sumOf { it.calories }
    val totalProtein = todayItems.sumOf { it.protein }
    val totalCarbs = todayItems.sumOf { it.carbs }
    val totalFat = todayItems.sumOf { it.fat }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Your Statistics") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            // Segmented control
            TabRow(
                selectedTabIndex = selectedTab,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Today") })
                Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("Trends") })
            }

            when (selectedTab) {
                0 -> TodayStatsView(
                    calories = totalCalories, protein = totalProtein,
                    carbs = totalCarbs, fat = totalFat,
                    items = todayItems
                )
                1 -> TrendsStatsView(last7Days = last7Days)
            }
        }
    }
}

@Composable
fun TodayStatsView(
    calories: Double, protein: Double, carbs: Double, fat: Double,
    items: List<com.example.portio.domain.model.FoodItem>
) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        InteractiveMacroCard(
            title = "CALORIES", value = calories, goal = 2200.0, unit = "kcal",
            color = MaterialTheme.colorScheme.tertiary,
            items = items.map { it.name to it.calories }
        )
        InteractiveMacroCard(
            title = "PROTEIN", value = protein, goal = 120.0, unit = "g",
            color = Color(0xFFE53935),
            items = items.map { it.name to it.protein }
        )
        InteractiveMacroCard(
            title = "CARBS", value = carbs, goal = 250.0, unit = "g",
            color = Color(0xFF1E88E5),
            items = items.map { it.name to it.carbs }
        )
        InteractiveMacroCard(
            title = "FAT", value = fat, goal = 70.0, unit = "g",
            color = Color(0xFF43A047),
            items = items.map { it.name to it.fat }
        )
    }
}

@Composable
fun InteractiveMacroCard(
    title: String,
    value: Double,
    goal: Double,
    unit: String,
    color: Color,
    items: List<Pair<String, Double>>
) {
    var expanded by remember { mutableStateOf(false) }
    val progress = if (goal > 0) (value / goal).coerceIn(0.0, 1.0).toFloat() else 0f
    val sortedItems = items.filter { it.second > 0 }.sortedByDescending { it.second }

    Card(
        modifier = Modifier.fillMaxWidth().clickable { expanded = !expanded },
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Text(
                        title,
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.ExtraBold,
                            letterSpacing = 1.sp
                        ),
                        color = color
                    )
                    Spacer(Modifier.height(6.dp))
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            value.roundToInt().toString(),
                            style = MaterialTheme.typography.displaySmall.copy(
                                fontWeight = FontWeight.Bold,
                                fontSize = 36.sp
                            )
                        )
                        Spacer(Modifier.width(4.dp))
                        Text(
                            "/ ${goal.roundToInt()} $unit",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(bottom = 4.dp)
                        )
                    }
                }

                // Circular progress
                Box(contentAlignment = Alignment.Center, modifier = Modifier.size(60.dp)) {
                    CircularProgressIndicator(
                        progress = { 1f },
                        modifier = Modifier.fillMaxSize(),
                        color = color.copy(alpha = 0.15f),
                        strokeWidth = 6.dp,
                        strokeCap = StrokeCap.Round
                    )
                    CircularProgressIndicator(
                        progress = { progress },
                        modifier = Modifier.fillMaxSize(),
                        color = color,
                        strokeWidth = 6.dp,
                        strokeCap = StrokeCap.Round
                    )
                    Text(
                        "${(progress * 100).roundToInt()}%",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        fontSize = 10.sp
                    )
                }
            }

            AnimatedVisibility(
                visible = expanded,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically() + fadeOut()
            ) {
                Column {
                    HorizontalDivider(Modifier.padding(vertical = 12.dp), color = color.copy(alpha = 0.2f))

                    if (sortedItems.isEmpty()) {
                        Text("No items logged yet", style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    } else {
                        sortedItems.take(5).forEach { (name, v) ->
                            Row(
                                Modifier.fillMaxWidth().padding(vertical = 4.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(name, style = MaterialTheme.typography.bodySmall, modifier = Modifier.weight(1f))
                                Text(
                                    "${v.roundToInt()}$unit",
                                    style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Bold),
                                    color = color
                                )
                            }
                        }
                    }

                    Spacer(Modifier.height(12.dp))
                    Text(
                        "${(progress * 100).roundToInt()}% of daily goal",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(4.dp))
                    LinearProgressIndicator(
                        progress = { progress },
                        modifier = Modifier.fillMaxWidth().height(10.dp).clip(RoundedCornerShape(5.dp)),
                        color = color,
                        trackColor = color.copy(alpha = 0.15f)
                    )
                }
            }
        }
    }
}

@Composable
fun TrendsStatsView(last7Days: List<DayStats>) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (last7Days.isEmpty()) {
            Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                Text("No data yet", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            return@Column
        }

        // Average summary cards
        val avgCalories = last7Days.map { it.calories }.average()
        val avgProtein = last7Days.map { it.protein }.average()

        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            AverageSummaryCard("Avg Calories", avgCalories, "kcal", Modifier.weight(1f))
            AverageSummaryCard("Avg Protein", avgProtein, "g", Modifier.weight(1f))
        }

        // Calorie trend chart
        CalorieTrendCard(last7Days = last7Days)

        // Macro distribution chart
        MacroDistributionCard(last7Days = last7Days)
    }
}

@Composable
fun AverageSummaryCard(title: String, value: Double, unit: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(4.dp))
            Text(
                "${value.roundToInt()} $unit",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
            )
        }
    }
}

@Composable
fun CalorieTrendCard(last7Days: List<DayStats>) {
    val modelProducer = remember { CartesianChartModelProducer() }

    LaunchedEffect(last7Days) {
        if (last7Days.isNotEmpty()) {
            modelProducer.runTransaction {
                lineSeries { series(last7Days.map { it.calories.toFloat().coerceAtLeast(0f) }) }
            }
        }
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Daily Calories",
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.weight(1f))
                Icon(Icons.Default.LocalFireDepartment, contentDescription = null,
                    tint = MaterialTheme.colorScheme.tertiary, modifier = Modifier.size(18.dp))
            }
            Spacer(Modifier.height(12.dp))
            CartesianChartHost(
                chart = rememberCartesianChart(rememberLineCartesianLayer()),
                modelProducer = modelProducer,
                modifier = Modifier.fillMaxWidth().height(180.dp)
            )
            // Day labels
            Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                last7Days.forEach { day ->
                    Text(day.dayLabel, style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 10.sp)
                }
            }
            // Calorie values below chart
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                last7Days.forEach { day ->
                    Text(
                        if (day.calories > 0) "${day.calories.roundToInt()}" else "-",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = MaterialTheme.colorScheme.tertiary,
                        fontSize = 9.sp
                    )
                }
            }
        }
    }
}

@Composable
fun MacroDistributionCard(last7Days: List<DayStats>) {
    val modelProducer = remember { CartesianChartModelProducer() }

    LaunchedEffect(last7Days) {
        if (last7Days.isNotEmpty()) {
            modelProducer.runTransaction {
                columnSeries {
                    series(last7Days.map { it.protein.toFloat().coerceAtLeast(0f) })
                    series(last7Days.map { it.carbs.toFloat().coerceAtLeast(0f) })
                    series(last7Days.map { it.fat.toFloat().coerceAtLeast(0f) })
                }
            }
        }
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)),
        elevation = CardDefaults.cardElevation(0.dp)
    ) {
        Column(Modifier.padding(20.dp)) {
            Text(
                "Macros Distribution",
                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(12.dp))
            CartesianChartHost(
                chart = rememberCartesianChart(rememberColumnCartesianLayer()),
                modelProducer = modelProducer,
                modifier = Modifier.fillMaxWidth().height(180.dp)
            )
            // Legend
            Row(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                LegendItem("Protein", Color(0xFFE53935))
                LegendItem("Carbs", Color(0xFF1E88E5))
                LegendItem("Fat", Color(0xFF43A047))
            }
        }
    }
}

@Composable
private fun LegendItem(label: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Box(Modifier.size(8.dp).clip(CircleShape).run { this }, contentAlignment = Alignment.Center) {
            Surface(color = color, modifier = Modifier.fillMaxSize(), shape = CircleShape) {}
        }
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
