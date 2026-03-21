package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

type Config struct {
	APIKey   string `json:"api_key"`
	GroupID  string `json:"group_id"`
	Endpoint string `json:"endpoint"`
}

func LoadConfig() (*Config, error) {
	cfg := &Config{}

	if key := os.Getenv("MINIMAX_CP_KEY"); key != "" {
		cfg.APIKey = key
	}
	if gid := os.Getenv("MINIMAX_GROUP_ID"); gid != "" {
		cfg.GroupID = gid
	}

	if cfg.APIKey == "" || cfg.GroupID == "" {
		data, err := os.ReadFile("config.json")
		if err != nil {
			return nil, fmt.Errorf("请设置环境变量 MINIMAX_CP_KEY 和 MINIMAX_GROUP_ID，或创建 config.json: %w", err)
		}
		if err := json.Unmarshal(data, cfg); err != nil {
			return nil, fmt.Errorf("解析 config.json 失败: %w", err)
		}
	}

	if cfg.APIKey == "" {
		return nil, fmt.Errorf("API Key 未设置，请设置 MINIMAX_CP_KEY 环境变量或 config.json")
	}

	if cfg.Endpoint == "" {
		cfg.Endpoint = "https://api.minimaxi.com"
	}

	return cfg, nil
}

func (c *Config) GetAuthHeader() string {
	return "Bearer " + c.APIKey
}

func formatTimestamp(ts int64) string {
	if ts == 0 {
		return "N/A"
	}
	return time.Unix(ts, 0).Format("2006-01-02 15:04:05")
}

func formatDuration(seconds int64) string {
	if seconds <= 0 {
		return "已重置"
	}
	h := seconds / 3600
	m := (seconds % 3600) / 60
	s := seconds % 60
	if h > 0 {
		return fmt.Sprintf("%d小时%d分%d秒", h, m, s)
	}
	if m > 0 {
		return fmt.Sprintf("%d分%d秒", m, s)
	}
	return fmt.Sprintf("%d秒", s)
}
