"""
Performance Testing Script: Compare Gemini Model Summarization Speed
Tests: Gemini 2.5 Flash-Lite vs 2.5 Flash vs 2.5 Pro
"""

import google.genai
import os
import time
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_path = Path(__file__).resolve().parent / 'backend' / '.env'
load_dotenv(env_path)

# Test data
TEST_TEXT = """
Photosynthesis is a process used by plants and other organisms to convert light energy 
into chemical energy that can later be released to fuel their activities. This chemical 
energy is stored in carbohydrate molecules, such as glucose, which are synthesized from 
carbon dioxide and water. In most cases, oxygen is also released as a waste product.

The rate of photosynthesis is influenced by several environmental factors including 
temperature, light intensity, carbon dioxide concentration, and water availability. 
Chlorophyll is the primary photosynthetic pigment that absorbs light energy. Different 
wavelengths of light are absorbed by different photosynthetic pigments. Photosynthesis 
occurs in two main stages: the light-dependent reactions and the light-independent reactions 
(also known as the Calvin cycle).

The light-dependent reactions take place in the thylakoid membranes of the chloroplasts. 
During this stage, light energy is converted into chemical energy in the form of ATP and NADPH. 
The light-independent reactions, or the Calvin cycle, use ATP and NADPH to convert carbon 
dioxide into glucose. This process is essential for the survival of most life forms on Earth, 
as it produces the oxygen we breathe and forms the base of most food chains.
"""

MODELS = [
    "gemini-2.5-flash-lite",
    "gemini-2.5-flash",
    "gemini-2.5-pro"
]

PROMPT = "Summarize the following study notes into 3 concise bullet points:\n\n"


def test_models():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("Error: GEMINI_API_KEY not found in .env file")
        return
    
    client = google.genai.Client(api_key=api_key)
    results = []
    
    print("Testing Gemini Models")
    print("=" * 50)
    
    for model in MODELS:
        try:
            print(f"\nTesting {model}...", end=" ", flush=True)
            
            start = time.time()
            response = client.models.generate_content(
                model=model,
                contents=PROMPT + TEST_TEXT
            )
            elapsed = time.time() - start
            
            results.append({
                "model": model,
                "time": elapsed,
                "summary": response.text
            })
            
            print(f"{elapsed:.2f}s")
            
        except Exception as e:
            print(f"Error: {str(e)}")
    
    # Print results
    print("\n" + "=" * 50)
    print("Results:")
    print("=" * 50)
    print(f"{'Model':<25} {'Time':<10}")
    print("-" * 35)
    
    for result in results:
        print(f"{result['model']:<25} {result['time']:.2f}s")
    
    # Ranking
    if results:
        print("\nRanking (Fastest to Slowest):")
        print("-" * 35)
        sorted_results = sorted(results, key=lambda x: x['time'])
        
        for i, result in enumerate(sorted_results, 1):
            print(f"{i}. {result['model']} - {result['time']:.2f}s")
    
    # Summaries
    print("\nSummaries:")
    print("=" * 50)
    
    for result in results:
        print(f"\n{result['model']}:")
        print(result['summary'][:200] + "...\n")


if __name__ == "__main__":
    test_models()
