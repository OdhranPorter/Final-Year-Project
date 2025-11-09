# 🎓 StudiBro: An AI Study Companion

**StudiBro** is a **native Android application** developed as a **Final Year Project** for the **BSc (Hons) in Computer Science** at **Atlantic Technological University (ATU)**.  

This intelligent study assistant transforms traditional study habits by turning passive note review into an **interactive, AI-enhanced learning experience**.  
By leveraging **Natural Language Processing (NLP)** and **Computer Vision**, StudiBro provides on-demand **note summarization**, **quiz generation**, and **OCR-based text capture** — all inspired by the cognitive science technique of *Active Recall*.

> 💡 *Final Year Project led by Odhran Porter.*

---

## 🚀 Core Features

### 🤖 AI-Powered Summaries
- Input large blocks of study text directly into the app.  
- StudiBro connects to the **Google Gemini API** to generate concise, easy-to-understand summaries.  
- Helps students retain key points quickly and efficiently.

### ❓ Automatic Quiz Generation
- Converts notes into an interactive quiz format.  
- Automatically generates context-relevant questions.  
- Enables students to **actively test comprehension** and strengthen memory retention.

### 📸 Optical Character Recognition (OCR)
- Uses **Google ML Kit** for real-time text recognition.  
- Instantly converts physical text to digital study notes from:
  - Textbooks  
  - Whiteboards  
  - Printed handouts  

### 📚 Personal Study Library
- Securely stores user notes, AI summaries, and generated quizzes.  
- Users can **organize**, **review**, and **reuse** their study materials anytime.  
- Data persistence via a **relational database backend**.

---

## 🏗️ System Architecture

StudiBro is a **full-stack mobile application** with a clear separation between the **Android client** and the **Django backend API**.

