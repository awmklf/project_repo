<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="spring" 	uri="http://www.springframework.org/tags" %>
<%@ taglib prefix="c" 		uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" 		uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt"   	uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="sec"		uri="http://www.springframework.org/security/tags" %>

<sec:authorize access="hasRole('ROLE_ADMIN') or hasRole('ROLE_MANAGER')" var="mngRole"/>
<sec:authorize access="hasRole('ROLE_ADMIN')" var="adminRole"/>
<sec:authorize access="isAuthenticated()">
	<sec:authentication property="principal" var="principal"/>
</sec:authorize>

<div>
	<div id="replyCnt"></div>
	<div id="replyList">
	</div>
	<sec:authorize access="isAuthenticated()">
		<div id="reply">
			<textarea rows="5" cols="50" id="replyContent" maxlength="1000" placeholder="덧글 내용 입력"></textarea>
			<button id="btn-addRep">작성</button>
		</div>
	</sec:authorize>
</div>


<template id="viewReplyTemplate">
    <div class="reply" id="">
        <div><strong class="nickname"></strong> | <span class="frstRegistPnttm"></span></div>
        <div class="parentReply"><strong class="parentNickname"></strong>님에게 답글</div>
        <div class="replyCn"></div>
        <sec:authorize access="isAuthenticated()">
			<button class="btn-editRepForm" data-reply-id="">수정</button>
       		<button class="btn-delRep" data-reply-id="">삭제</button>
        	<button class="btn-addChildRepForm" data-reply-id="">답글</button>
        </sec:authorize>
    </div>
</template>

<template id="replyRegistTemplate">
	<div class="reply-form">
		<textarea rows="5" cols="50" maxlength="1000" class="replyContent" id="" placeholder="답글 내용 입력"></textarea>
		<button class="btn-submitRep" data-reply-id="${replyId}">작성</button>
	</div>
</template>
<script>
	$(document).ready(function() {
		var token = $("meta[name='_csrf']").attr("content");
		var header = $("meta[name='_csrf_header']").attr("content");
		var boardIdNum = $("#boardIdNum").val();
		
		// 덧글 목록 조회 실행
		viewReplyList();
		
		// 덧글 목록 조회
		function viewReplyList() {
	    	$.ajax({
	    		url: '/reply/list/' + boardIdNum,
	    		type: 'get',
	    		success: function (data) {
	    			var replyList = $('#replyList');
    	            replyList.empty();
					$('#replyCnt').text('덧글 : ' + data.totRepListCnt);
    	            data.RepList.forEach(function(reply) {
    	            	var updatedRep = '';
    	            	var replyViewTemplate = $('#viewReplyTemplate').contents().clone(); // 템플릿 복제
                        if (reply.parentReplyId) { // 덧글에 대한 답글인 경우
                            replyViewTemplate.addClass('reply-indent');
                            replyViewTemplate.find('.parentReply').show();
                            replyViewTemplate.find('.parentNickname').text(reply.parentNickname);
                        } else {
                        	 replyViewTemplate.find('.parentReply').remove();
                        }
                        replyViewTemplate.attr('id', reply.replyId);
    	            	replyViewTemplate.find('.nickname').text(reply.nickname);
    	            	if (reply.useAt == 'Y' && reply.lastUpdtPnttm != null) {
    	            		updatedRep = '(' + reply.lastUpdtPnttm + ' 수정됨)';
						}
                        replyViewTemplate.find('.frstRegistPnttm').text(reply.frstRegistPnttm + updatedRep);
                        replyViewTemplate.find('.replyCn').text(reply.replyCn);
                        if ('${principal.username}' == reply.registerId || ${adminRole}) { // 수정 버튼 권한 확인
                            replyViewTemplate.find('.btn-editRepForm').attr('data-reply-id', reply.replyId);
                        } else {
                            replyViewTemplate.find('.btn-editRepForm').remove();
                        }
                        if ('${principal.username}' == reply.registerId || ${mngRole}) { // 삭제 버튼 권한 확인
                            replyViewTemplate.find('.btn-delRep').attr('data-reply-id', reply.replyId);
                        } else {
                            replyViewTemplate.find('.btn-delRep').remove();
                        }
                        replyViewTemplate.find('.btn-editRepForm').attr('data-reply-id', reply.replyId);
                        replyViewTemplate.find('.btn-delRep').attr('data-reply-id', reply.replyId);
                        replyViewTemplate.find('.btn-addChildRepForm').attr('data-reply-id', reply.replyId);
    	                replyList.append(replyViewTemplate); // 복제된 템플릿 추가
    	            });
    	            
					$('.btn-editRepForm').click(function() { // 수정 버튼 이벤트
						replyForm.call(this);
   	                });
   	                $('.btn-delRep').click(function() { // 삭제 버튼 이벤트
   	                	delReply.call(this);
   	                });
   	                $('.btn-addChildRepForm').click(function() { // 답글 작성 버튼 이벤트
   	                	replyForm.call(this);
   	                });
	    		},
	    		error: function (xhr, status, error) {
	                console.error(error);
	                alert('덧글 목록을 불러오는 중 오류가 발생했습니다.');
	    		}
	    	});
	    }
		
   		$('#btn-addRep').click(addReply); // 덧글 작성 버튼 이벤트

		
		// 답글or수정창 띄우기
		function replyForm () {
			$('.reply-form').remove();
			var replyId = $(this).data('reply-id');
			var btnClass = $(this).attr('class');
			var editReplyTemplate = $('#replyRegistTemplate').contents().clone();
			editReplyTemplate.find('.replyContent').attr('id', 'replyContent_' + replyId);
			editReplyTemplate.find('.btn-submitRep').attr('data-reply-id', replyId);
			if (btnClass == 'btn-editRepForm') { // 수정인 경우
				var replyCn = $('#' + replyId).find('.replyCn').text();
				editReplyTemplate.find('.replyContent').text(replyCn);
				editReplyTemplate.find('.btn-submitRep').text('수정');
			}
			$('#' + replyId).append(editReplyTemplate);
			$('.btn-submitRep').click(function() {
				if (btnClass == 'btn-editRepForm') {
					editReply.call(this);
				} else {
					addReply.call(this);
				}
			});
		}

		// 덧글 등록
		function addReply () {
			if (!confirm("등록하시겠습니까?")) {
				return false;
			}
			var btnClass = $(this).attr('class');
			var parentReplyId;
			var replyContent;
			if (btnClass == 'btn-submitRep') { // 답글 등록
				parentReplyId = $(this).data('reply-id');
				replyContent = $('#replyContent_' + parentReplyId).val();
				if (!replyContent.trim()) {
					alert("내용을 입력해주세요.");
					return false;
				}
			} else { // 덧글 등록
				parentReplyId;
				replyContent = $('#replyContent').val();
				if (!replyContent.trim()) {
					alert("내용을 입력해주세요.");
					return false;
				}
			}
			$.ajax({
				url: '/reply/' + boardIdNum + '/add',
				type: 'post',
				data: {
					replyCn: replyContent,
					parentReplyId: parentReplyId
				},
				beforeSend: function(xhr){
					xhr.setRequestHeader(header, token);
					xhr.setRequestHeader("Accept", "application/json");
				},
				success: function(response) {
					if (response.addRepCnt == 1) {
						viewReplyList();
						$('#replyContent').val('');
					} else {
						alert('정상적으로 반영되지 않았습니다.');
					}
				},
				error: function(error) {
					console.error('Error occurred: ' + error);
					if (error.responseJSON && error.responseJSON.message) {
				        alert(error.responseJSON.message);
				    } else {
						alert('오류가 발생했습니다.');
					}
				}
			});
		}
		
		// 덧글 수정
		function editReply () {
			if (!confirm("등록하시겠습니까?")) {
				return false;
			}
			var replyId = $(this).data('reply-id');
			var replyContent = $('#replyContent_' + replyId).val();
			
			$.ajax({
				url: '/reply/' + boardIdNum + '/edit',
				type: 'post',
				data: {
					replyCn: replyContent,
					replyId: replyId
				},
				beforeSend: function(xhr){
					xhr.setRequestHeader(header, token);
					xhr.setRequestHeader("Accept", "application/json");
				},
				success: function(response) {
					if (response.editReplyCnt == 1) {
						viewReplyList();
					} else {
						alert('정상적으로 반영되지 않았습니다.');
					}
				},
				error: function(error) {
					console.error('Error occurred: ' + error);
					if (error.responseJSON && error.responseJSON.message) {
				        alert(error.responseJSON.message);
				    } else {
						alert('오류가 발생했습니다.');
					}
				}
			});
		}
		
		// 덧글 삭제
		function delReply () {
			if (!confirm("삭제하시겠습니까?")) {
				return false;
			}
			var replyId = $(this).data('reply-id');
			
			$.ajax({
				url: '/reply/' + boardIdNum + '/delete',
				type: 'post',
				data: {
					replyId: replyId
				},
				beforeSend: function(xhr){
					xhr.setRequestHeader(header, token);
					xhr.setRequestHeader("Accept", "application/json");
				},
				success: function(response) {
					if (response.delReplyCnt == 1) {
						viewReplyList();
					} else {
						alert('정상적으로 반영되지 않았습니다.');
					}
				},
				error: function(error) {
// 					console.error('Error occurred: ' + error);
					if (error.responseJSON && error.responseJSON.message) {
				        alert(error.responseJSON.message);
				    } else {
						alert('오류가 발생했습니다.');
					}
				}
			});
		}
		
	});
</script>