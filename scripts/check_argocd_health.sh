check_argocd_health() {
  local max_attempts=10
  local attempt=1
  local wait_time=10
  
  printf "Waiting for ArgoCD to be accessible at https://argocd.test.com...\n"
  
  while [ $attempt -le $max_attempts ]; do
    printf "Attempt $attempt/$max_attempts: "
    
    # Check if ArgoCD responds with HTTP 200 or redirect (3xx)
    response_code=$(curl -kv -w "%{http_code}" -o /dev/null -s --connect-timeout 5 --max-time 10 https://argocd.test.com 2>/dev/null)
    
    if [ "$response_code" = "200" ] || [ "$response_code" = "302" ] || [ "$response_code" = "301" ] || [ "$response_code" = "307" ]; then
      printf "✅ SUCCESS! ArgoCD is accessible (HTTP $response_code)\n"
      printf "🌐 ArgoCD UI: https://argocd.test.com\n"
      # printf "👤 Username: admin\n"
      # printf "🔑 Password: $ARGOCD_PWD\n"
      return 0
    else
      printf "❌ Failed (HTTP $response_code). Retrying in ${wait_time}s...\n"
    fi
    
    sleep $wait_time
    attempt=$((attempt + 1))
  done
  
  printf "⚠️  ArgoCD health check failed after $max_attempts attempts\n"
  printf "🔍 Troubleshooting commands:\n"
  printf "   kubectl get pods -n argocd\n"
  printf "   kubectl get ing -n argocd\n"
  printf "   kubectl logs -n argocd deployment/argocd-server\n"
  return 1
}
