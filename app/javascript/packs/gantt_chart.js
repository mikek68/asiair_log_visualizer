document.addEventListener('DOMContentLoaded', () => {
    gantt.plugins({ 
        tooltip: true 
    });

    gantt.templates.tooltip_text = function(start, end, task) {
        return task.tool_tip_text;
    };

    gantt.config.scales = [
        { unit: "month", step: 1, format: "%F, %Y" },
        { unit: "day", step: 1, format: "%D - %j" },
        { unit: "hour", step: 1, date: "%H:%i" },
    ];

    gantt.config.columns = [
        { name: "text", label: "Task name", width: 250, resize: false, tree: true },
        { name: "start_date", label: "Start Time", align: "center", resize: false, width: 160 },
        { name: "end_date", label: "End Time", align: "center", resize: false, width: 160 },
        { name: "log_messages", label: "Log Messages", align: "center", resize: false, width: 140 },
    ];

    gantt.config.scale_height = 54;
    gantt.config.drag_links = false;
    gantt.config.drag_progress = false;
    gantt.config.drag_resize = false;
    gantt.config.drag_move = false;
    gantt.config.readonly = true;
    gantt.config.date_grid = "%Y-%m-%d %H:%i:%s";

    gantt.setSkin("dark");

    const logGanttChart = document.getElementById('log_gantt_chart');
    if (logGanttChart) {
        gantt.init(logGanttChart);
        gantt.clearAll();
        gantt.load(logGanttChart.dataset.loadUrl);
    }
});