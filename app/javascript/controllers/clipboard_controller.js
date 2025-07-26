import { Controller } from "@hotwired/stimulus"

// Handles copying text to clipboard with visual feedback
export default class extends Controller {
  static targets = ["source", "button"]
  
  copy(event) {
    event.preventDefault()
    
    const text = this.sourceTarget.value || this.sourceTarget.textContent
    
    navigator.clipboard.writeText(text).then(() => {
      // Visual feedback
      const originalText = this.buttonTarget.textContent
      this.buttonTarget.textContent = "Copied!"
      this.buttonTarget.classList.add("bg-green-600")
      this.buttonTarget.classList.remove("bg-cyan-600", "hover:bg-cyan-700")
      
      // Reset after 2 seconds
      setTimeout(() => {
        this.buttonTarget.textContent = originalText
        this.buttonTarget.classList.remove("bg-green-600")
        this.buttonTarget.classList.add("bg-cyan-600", "hover:bg-cyan-700")
      }, 2000)
    }).catch(err => {
      console.error('Failed to copy text: ', err)
      this.buttonTarget.textContent = "Failed to copy"
    })
  }
}