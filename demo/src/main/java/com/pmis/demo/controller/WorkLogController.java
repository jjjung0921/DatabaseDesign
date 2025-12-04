package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.TaskWorkLog;
import com.pmis.demo.dto.WorkLogRequest;
import com.pmis.demo.service.WorkLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks/{taskId}/worklogs")
@RequiredArgsConstructor
public class WorkLogController {

    private final WorkLogService workLogService;

    @PostMapping
    public TaskWorkLog logWork(@PathVariable Long taskId,
                               @RequestBody WorkLogRequest request) {
        return workLogService.logWork(
                taskId,
                request.getEmployeeId(),
                request.getWorkDate(),
                request.getHours(),
                request.getNote()
        );
    }

    @GetMapping
    public List<TaskWorkLog> getLogs(@PathVariable Long taskId) {
        return workLogService.getTaskLogs(taskId);
    }
}
