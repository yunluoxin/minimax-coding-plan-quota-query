#!/usr/bin/env python3
"""MiniMax Coding Plan 用量查询工具"""

import argparse
import json
import sys
import urllib.request


ENDPOINTS = {
    "cn": "https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains",
    "intl": "https://api.minimax.io/v1/api/openplatform/coding_plan/remains",
}


def query(api_key: str, group_id: str = "", region: str = "cn") -> dict:
    url = ENDPOINTS[region]
    if group_id:
        url += f"?GroupId={group_id}"

    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    })

    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def fmt_ms(ts: int) -> str:
    from datetime import datetime, timezone
    return datetime.fromtimestamp(ts / 1000, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def fmt_seconds(s: int) -> str:
    h, rem = divmod(s, 3600)
    m, _ = divmod(rem, 60)
    return f"{h}h {m}m"


def main():
    parser = argparse.ArgumentParser(description="MiniMax Coding Plan 用量查询")
    parser.add_argument("api_key", help="Coding Plan API Key (sk-cp-...)")
    parser.add_argument("--group-id", "-g", default="", help="GroupId (可选)")
    parser.add_argument("--region", "-r", choices=["cn", "intl"], default="cn", help="节点: cn(国内) / intl(国际)")
    args = parser.parse_args()

    try:
        data = query(args.api_key, args.group_id, args.region)
    except Exception as e:
        print(f"请求失败: {e}", file=sys.stderr)
        sys.exit(1)

    base = data.get("base_resp", {})
    if base.get("status_code") != 0:
        print(f"API 错误: {base.get('status_msg')}", file=sys.stderr)
        sys.exit(1)

    models = data.get("model_remains", [])

    print(f"模型数: {len(models)}")
    print(f"{'模型':<35} {'剩余':>8} {'总额':>8}  剩余时间    区间截止时间")
    print("-" * 75)

    for m in models:
        total = m["current_interval_total_count"]
        remaining = m["current_interval_usage_count"]
        remains_str = fmt_seconds(m["remains_time"] // 1000)
        end_time_str = fmt_ms(m["end_time"])
        print(f"{m['model_name']:<35} {remaining:>8} {total:>8}  {remains_str:>10}  {end_time_str}")


if __name__ == "__main__":
    main()
