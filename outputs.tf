output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "alb_dns_name" {
  value = aws_lb.ecs_alb.dns_name
}

# filepath: /home/amye/Documents/VeracrossECS/outputs.tf
output "alb_url" {
  value = "http://${aws_lb.ecs_alb.dns_name}"
  description = "URL to access the ECS service"
}
