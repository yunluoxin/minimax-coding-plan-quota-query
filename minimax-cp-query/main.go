package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"
)

var debugMode bool

type APIResponse struct {
	ModelRemains []ModelRemain `json:"model_remains"`
	BaseResp     BaseResp      `json:"base_resp"`
}

type BaseResp struct {
	StatusCode int    `json:"status_code"`
	StatusMsg  string `json:"status_msg"`
}

type ModelRemain struct {
	ModelName                 string `json:"model_name"`
	CurrentIntervalTotalCount int    `json:"current_interval_total_count"`
	CurrentIntervalUsageCount int    `json:"current_interval_usage_count"`
	RemainsTime               int64  `json:"remains_time"`
	StartTime                 int64  `json:"start_time"`
	EndTime                   int64  `json:"end_time"`
	CurrentWeeklyTotalCount   int    `json:"current_weekly_total_count"`
	CurrentWeeklyUsageCount   int    `json:"current_weekly_usage_count"`
	WeeklyRemainsTime         int64  `json:"weekly_remains_time"`
}

func main() {
	for _, arg := range os.Args[1:] {
		if arg == "-v" || arg == "--debug" {
			debugMode = true
		}
	}

	cfg, err := LoadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "配置错误: %v\n", err)
		os.Exit(1)
	}

	if debugMode {
		fmt.Fprintf(os.Stderr, "[DEBUG] Endpoint: %s\n", cfg.Endpoint)
		fmt.Fprintf(os.Stderr, "[DEBUG] GroupID: %s\n", cfg.GroupID)
	}

	result, err := fetchWithDebug(cfg.Endpoint, cfg.GroupID, cfg.GetAuthHeader())
	if err != nil {
		fmt.Fprintf(os.Stderr, "查询失败: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("╔══════════════════════════════════════════════════════════╗")
	fmt.Println("║          MiniMax Coding Plan 实时用量查询                 ║")
	fmt.Println("╠══════════════════════════════════════════════════════════╣")

	if len(result.ModelRemains) > 0 {
		m := result.ModelRemains[0]
		fmt.Printf("║  当前窗口: %s                          ║\n", formatTimestampMs(m.StartTime))
		fmt.Printf("║  窗口结束: %s                          ║\n", formatTimestampMs(m.EndTime))
		fmt.Printf("║  窗口剩余: %-46s║\n", formatDurationMs(m.RemainsTime))
	}
	fmt.Println("╠══════════════════════════════════════════════════════════╣")
	fmt.Println("║  模型名称                              已用    总额    剩余  ║")
	fmt.Println("╠══════════════════════════════════════════════════════════╣")

	for _, m := range result.ModelRemains {
		used := m.CurrentIntervalTotalCount - m.CurrentIntervalUsageCount
		name := m.ModelName
		if len(name) > 30 {
			name = name[:27] + "..."
		}
		fmt.Printf("║  %-30s %6d  %6d  %6d  ║\n",
			name, used, m.CurrentIntervalTotalCount, m.CurrentIntervalUsageCount)
	}

	fmt.Println("╚══════════════════════════════════════════════════════════╝")
}

func formatTimestampMs(ms int64) string {
	if ms == 0 {
		return "N/A"
	}
	return time.Unix(ms/1000, 0).Format("2006-01-02 15:04:05")
}

func formatDurationMs(ms int64) string {
	if ms <= 0 {
		return "已重置"
	}
	totalSec := ms / 1000
	h := totalSec / 3600
	m := (totalSec % 3600) / 60
	s := totalSec % 60
	if h > 0 {
		return fmt.Sprintf("%d小时%d分%d秒", h, m, s)
	}
	if m > 0 {
		return fmt.Sprintf("%d分%d秒", m, s)
	}
	return fmt.Sprintf("%d秒", s)
}

func fetchWithDebug(endpoint, groupID, authHeader string) (*APIResponse, error) {
	apiPath := "/v1/api/openplatform/coding_plan/remains"

	reqURL := endpoint + apiPath
	if groupID != "" {
		reqURL += "?GroupId=" + url.QueryEscape(groupID)
	}

	if debugMode {
		fmt.Fprintf(os.Stderr, "[DEBUG] Request URL: %s\n", reqURL)
		fmt.Fprintf(os.Stderr, "[DEBUG] Auth Header: Bearer sk-cp-***\n")
	}

	client := &http.Client{Timeout: 15 * time.Second}

	req, err := http.NewRequest("GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %w", err)
	}

	req.Header.Set("Authorization", authHeader)
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %w", err)
	}

	if debugMode {
		fmt.Fprintf(os.Stderr, "[DEBUG] Status: %d\n", resp.StatusCode)
		fmt.Fprintf(os.Stderr, "[DEBUG] Response Body: %s\n", string(body))
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("请求失败，状态码: %d，响应: %s", resp.StatusCode, string(body))
	}

	var result APIResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("解析响应失败: %w，原始响应: %s", err, string(body))
	}

	if result.BaseResp.StatusCode != 0 {
		return nil, fmt.Errorf("API 返回错误，代码: %d，消息: %s", result.BaseResp.StatusCode, result.BaseResp.StatusMsg)
	}

	return &result, nil
}
