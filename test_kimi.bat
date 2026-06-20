@echo off
setlocal

curl -X POST https://api.moonshot.cn/v1/chat/completions ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %MOONSHOT_API_KEY%" ^
  -d "{\"model\":\"moonshot-v1-8k\",\"messages\":[{\"role\":\"user\",\"content\":\"你好，请回复：Kimi 通讯测试成功\"}],\"temperature\":0.3}"

echo.
pause