import { Controller } from "@hotwired/stimulus"

// Handles dynamic time slot management and preview functionality for scheduling polls
export default class extends Controller {
  static targets = ["timeSlotsContainer", "timeSlot", "preview", "previewContent", "timeSlotTemplate"]
  
  connect() {
    console.log("SchedulingPollController connected")
  }
  
  addTimeSlot(event) {
    event.preventDefault()
    
    const template = this.timeSlotTemplateTarget
    const container = this.timeSlotsContainerTarget
    const newIndex = new Date().getTime()
    
    // Clone the template content
    const newSlot = template.content.cloneNode(true)
    
    // Update the name attributes with proper index
    newSlot.querySelectorAll('input, select').forEach(input => {
      const name = input.getAttribute('name')
      if (name) {
        input.setAttribute('name', name.replace('NEW_RECORD', newIndex))
      }
    })
    
    container.appendChild(newSlot)
  }
  
  removeTimeSlot(event) {
    event.preventDefault()
    
    const timeSlot = event.target.closest('[data-scheduling-poll-target="timeSlot"]')
    
    // If this is an existing record, mark it for deletion
    const destroyField = timeSlot.querySelector('input[name*="_destroy"]')
    if (destroyField) {
      destroyField.value = '1'
      timeSlot.style.display = 'none'
    } else {
      // Otherwise, just remove it from the DOM
      timeSlot.remove()
    }
  }
  
  preview(event) {
    event.preventDefault()
    
    const title = document.querySelector('input[name="scheduling_poll[title]"]').value
    const description = document.querySelector('textarea[name="scheduling_poll[description]"]').value
    const timeSlots = this.timeSlotTargets.filter(slot => slot.style.display !== 'none')
    
    let previewHtml = `<h4 class="text-xl font-semibold text-white mb-2">${title || 'Untitled Poll'}</h4>`
    
    if (description) {
      previewHtml += `<p class="text-gray-400 mb-4">${description}</p>`
    }
    
    previewHtml += '<div class="space-y-2">'
    previewHtml += '<p class="text-sm font-medium text-gray-300">Time Slots:</p>'
    
    timeSlots.forEach(slot => {
      const dateInput = slot.querySelector('input[type="datetime-local"]')
      const durationSelect = slot.querySelector('select')
      
      if (dateInput && dateInput.value) {
        const date = new Date(dateInput.value)
        const duration = durationSelect ? durationSelect.options[durationSelect.selectedIndex].text : '3 hours'
        
        previewHtml += `
          <div class="ml-4 text-gray-300">
            • ${date.toLocaleDateString()} at ${date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})} - ${duration}
          </div>
        `
      }
    })
    
    previewHtml += '</div>'
    
    this.previewContentTarget.innerHTML = previewHtml
    this.previewTarget.classList.remove('hidden')
  }
}