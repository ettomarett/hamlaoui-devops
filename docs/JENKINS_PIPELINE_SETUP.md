# 🚀 Jenkins Pipeline Setup Guide for E-Commerce Microservices

## 📋 **Prerequisites Checklist**

✅ Jenkins is accessible at: `http://20.86.144.152:31080`  
✅ Authentication is disabled (no login required)  
✅ Microservices are deployed and running  
✅ Docker registry is available at `localhost:32000`  
✅ Kubernetes cluster is operational  

## 🎯 **Step 1: Access Jenkins Dashboard**

1. **Open your browser** and navigate to: `http://20.86.144.152:31080`
2. You should see the Jenkins dashboard directly (no login required)
3. If you see a login page, the authentication wasn't properly disabled

## 🔧 **Step 2: Create New Pipeline Job**

### **2.1 Create New Item**
1. Click **"New Item"** on the left sidebar
2. Enter job name: `E-Commerce-Microservices-Pipeline`
3. Select **"Pipeline"** as the project type
4. Click **"OK"**

### **2.2 Configure Pipeline**
1. **General Settings:**
   - ✅ Check "GitHub project" (optional)
   - Project URL: `https://github.com/hamlaoui/hamlaoui-devops`

2. **Build Triggers:**
   - ✅ Check "Poll SCM" for automatic builds
   - Schedule: `H/5 * * * *` (checks every 5 minutes)
   - OR ✅ Check "GitHub hook trigger for GITScm polling" for webhook

3. **Pipeline Configuration:**
   - Definition: **"Pipeline script from SCM"**
   - SCM: **Git**
   - Repository URL: `https://github.com/hamlaoui/hamlaoui-devops.git`
   - Branch: `*/main` (or your default branch)
   - Script Path: `Jenkinsfile-Enhanced`

4. Click **"Save"**

## 🚀 **Step 3: Run Your First Build**

### **3.1 Manual Build**
1. Go to your pipeline job
2. Click **"Build Now"**
3. Watch the build progress in the **"Build History"**
4. Click on the build number to see detailed logs

### **3.2 Expected Pipeline Stages**
Your pipeline will execute these stages:
1. 🚀 **Pipeline Start** - Checkout code and setup
2. 🔍 **Environment Check** - Verify tools (Java, Maven, Docker, kubectl)
3. 📦 **Build Microservices** - Parallel build of all 3 services
4. 🧪 **Run Tests** - Execute unit tests for each service
5. 🐳 **Build Docker Images** - Create Docker images for each service
6. 📤 **Push to Registry** - Push images to local registry
7. ☸️ **Deploy to Kubernetes** - Update K8s deployments
8. 🔍 **Health Check** - Verify all services are healthy
9. 🧹 **Cleanup** - Remove old Docker images

## 📊 **Step 4: Monitor Pipeline Execution**

### **4.1 Build Console Output**
- Click on build number → **"Console Output"**
- Look for colored emojis and status messages
- Each stage shows detailed progress

### **4.2 Pipeline Visualization**
- Go to your job → **"Pipeline"** tab
- See visual representation of pipeline stages
- Green = Success, Red = Failed, Blue = Running

### **4.3 Expected Success Messages**
```
🎉 PIPELINE COMPLETED SUCCESSFULLY! 
✅ All microservices deployed and healthy

🌐 SERVICE ENDPOINTS:
🛍️  Product Service:    http://20.86.144.152:31309/actuator/health
📦 Inventory Service:  http://20.86.144.152:31081/actuator/health  
🛒 Order Service:      http://20.86.144.152:31004/actuator/health
```

## 🔧 **Step 5: Configure Advanced Features**

### **5.1 Email Notifications (Optional)**
1. Go to **"Manage Jenkins"** → **"Configure System"**
2. Find **"E-mail Notification"** section
3. Configure SMTP server settings
4. Test email configuration

### **5.2 Slack Integration (Optional)**
1. Install **"Slack Notification Plugin"**
2. Configure Slack workspace and channel
3. Update `NOTIFICATION_WEBHOOK` in Jenkinsfile-Enhanced
4. Add Slack notifications to pipeline

### **5.3 Build Parameters**
Add these parameters to make pipeline configurable:
- `DEPLOY_ENVIRONMENT` (dev/staging/prod)
- `SKIP_TESTS` (true/false)
- `DOCKER_TAG` (custom tag for images)

## 🐛 **Step 6: Troubleshooting Common Issues**

### **6.1 Build Fails at Maven Stage**
```bash
# Check if Maven is installed in Jenkins
mvn -version

# Verify Java version
java -version
```

**Solution:** Install Maven plugin or configure Maven in Global Tool Configuration

### **6.2 Docker Build Fails**
```bash
# Check Docker daemon
docker --version
docker ps
```

**Solution:** Ensure Jenkins user has Docker permissions

### **6.3 Kubernetes Deployment Fails**
```bash
# Check kubectl access
kubectl get nodes
kubectl get deployments
```

**Solution:** Configure kubeconfig for Jenkins user

### **6.4 Health Check Fails**
- Verify services are running: `kubectl get pods`
- Check service endpoints are accessible
- Review application logs: `kubectl logs <pod-name>`

## 📈 **Step 7: Pipeline Optimization**

### **7.1 Parallel Execution**
The pipeline already uses parallel stages for:
- Building all 3 microservices simultaneously
- Running tests in parallel
- Building Docker images concurrently

### **7.2 Caching**
- Maven dependencies are cached between builds
- Docker layer caching speeds up image builds
- Workspace cleanup prevents disk space issues

### **7.3 Build Artifacts**
- JAR files are automatically archived
- Test reports are preserved
- Build logs are retained for analysis

## 🎯 **Step 8: Next Steps & Best Practices**

### **8.1 Set Up Webhooks**
1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://20.86.144.152:31080/github-webhook/`
4. Content type: `application/json`
5. Events: Push events

### **8.2 Create Multiple Environments**
- **Development Pipeline:** Automatic on every commit
- **Staging Pipeline:** Manual trigger for testing
- **Production Pipeline:** Manual approval required

### **8.3 Add Quality Gates**
- Code coverage thresholds
- Security scanning with tools like SonarQube
- Performance testing integration

### **8.4 Monitoring Integration**
- Connect to Grafana dashboards
- Set up alerts for failed builds
- Monitor deployment metrics

## 🎉 **Success Criteria**

Your pipeline is successfully set up when:

✅ **Build completes without errors**  
✅ **All 3 microservices are built and tested**  
✅ **Docker images are created and pushed**  
✅ **Kubernetes deployments are updated**  
✅ **Health checks pass for all services**  
✅ **Services are accessible via their endpoints**  

## 📞 **Getting Help**

If you encounter issues:

1. **Check Jenkins Console Output** for detailed error messages
2. **Review Build Logs** for each failed stage
3. **Verify Prerequisites** (Docker, kubectl, Maven access)
4. **Test Individual Commands** manually on Jenkins server
5. **Check Service Status** in Kubernetes cluster

## 🚀 **Ready to Build!**

Your Jenkins pipeline is now configured and ready to automate your e-commerce microservices deployment. Every code change will trigger a complete build, test, and deployment cycle, ensuring your application is always up-to-date and healthy!

**Happy Building! 🎯** 