class SubmitsController < ApplicationController

	#
	# Manages submits in admin interfaces like /students and the student search
	# -only course heads need access
	#

	before_action :authorize
	before_action :require_senior

	# GET /submits/:id
	# sends javascript to fill a modal-browser
	def show
		load_submit(params[:id])
	end
	
	# POST /submits with :pset_id, :user_id
	# sends javascript to fill a modal-browser
	def create
		submit = Submit.where(params[:submit].permit([:pset_id, :user_id])).first_or_create
		logger.info "HIER #{submit.inspect}"
		load_submit(submit.id)
		render 'show'
	end
	
	# DELETE /submits/:id
	# does not send javascript, instead refreshes full view via redirect_back
	def destroy
		@submit = Submit.find(params[:id])
		@submit.destroy
		respond_to do |format|
			format.js { redirect_js location: user_path(@submit.user) }
			format.html { redirect_back fallback_location: root_path }
		end
	end
	
	# GET /submits/form_for_missing
	def form_for_missing
		@schedule = current_user.schedule
		@users = @schedule.users.not_staff.not_inactive
		@psets = Pset.all
		render layout: "application"
	end

	# POST /submits/notify_missing
	def notify_missing
		@schedule = current_user.schedule
		@pset = Pset.find(params[:pset_id])
		@users = @schedule.users.not_staff.not_inactive

		@users.each do |u|
			if !@pset.submit_from(u)
				NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver
			end
		end
		redirect_to({ action: "index" }, notice: 'E-mails are being sent.')
	end
	
	private
	
	def load_submit(id)
		# load the submit and any grade that might be attached
		@submit = Submit.includes(:grade, :user, :pset).find(id)
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })

		# load files submitted in child psets if we want to grade a parent module
		@files_from_module = @submit.user.files_for_module(@submit.pset.mod) if @submit.pset.mod

		# either use the files attached to this specific submit, or all gathered from the module
		@files = @submit.file_contents || @files_from_module
	end

end
