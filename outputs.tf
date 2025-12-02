output "api_invoke_url" {
  description = "Base invoke URL of API Gateway"
  value       = aws_api_gateway_deployment.todo_deploy.invoke_url
}
