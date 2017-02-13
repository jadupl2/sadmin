

<?php
    echo "\n</div>                             <!-- End of Div sadmMainBodyPage -->";
    echo "\n</div>                             <!-- End of Div sadmMainBody -->";
    echo "\n</div>                             <!-- End of Div sadmSideBarAndBodyContainer -->";

    echo "\n\n\n<!-- ========================================================================= -->";
    echo "\n<div id='sadmFooter'>";
    echo "\n   Copyright &copy; 2016 - www.sadmin.ca"; 
    echo "\n   <br><small>Contact, corrections and suggestions: Jacques Duplessis</small>";
    echo "\n</div>                              <!-- End of Div sadmFooter -->\n";
    echo "\n<!-- ============================================================================= -->";
    echo "\n\n</div>                            <!-- End of Div sadmContainer -->\n";

    # Close DataBase Connection
    pg_close($connection);
 ?>    

    <!-- Bootstrap core JavaScript -->
    <script src="/js/jquery-1.12.3.min.js"></script>
    <script src="/js/bootstrap.min.js"></script> 
    <script src="/js/jquery.dataTables.min.js"></script>
 
    <!-- Bootstrap TooTips JavaScript -->
    <script> 
    $(document).ready(function(){ $('[data-toggle="tooltip"]').tooltip();   }); 
    $(document).ready(function(){ 
        $('#sadmTable').DataTable({
            searching: true,
            ordering: true,
            lengthMenu: [[20, 50, 100, -1], [20, 50, 100, "All"]],
            pageLength: 50 ,
            bAutoWidth: false 
/*            order: [[ 2, 'desc' ], [ 3, 'desc' ]]*/
 /*       "aoColumns" : [
            { sWidth: '50px' },
            { sWidth: '100px' },
            { sWidth: '70px' },
            { sWidth: '50px' },
            { sWidth: '50px' },
            { sWidth: '50px' }
        ]  */
/*                columns: [
                { data: 'id', name: 'id' , width: '50px', class: 'text-right' },
                { data: 'name', name: 'name' width: '50px', class: 'text-right' }
                ]*/            
        });
    } ); 

    </script>     
    
    
<script type="text/javascript" src="/js/bootstrap-datetimepicker.js" charset="UTF-8"></script>
<script type="text/javascript" src="/js/locales/bootstrap-datetimepicker.fr.js" charset="UTF-8"></script>
<script type="text/javascript">
    $('.form_datetime').datetimepicker({
        //language:  'fr',
        weekStart: 1,
        todayBtn:  1,
		autoclose: 1,
		todayHighlight: 1,
		startView: 2,
		forceParse: 0,
        showMeridian: 1
    });
	$('.form_date').datetimepicker({
        //language:  'fr',
        weekStart: 1,
        todayBtn:  1,
		autoclose: 1,
		todayHighlight: 1,
		startView: 2,
		minView: 2,
		forceParse: 0
    });
	$('.form_time').datetimepicker({
        //language:  'fr',
        weekStart: 1,
        todayBtn:  1,
		autoclose: 1,
		todayHighlight: 1,
		startView: 1,
		minView: 0,
		maxView: 1,
		forceParse: 0
    });
</script>
</body>
</html>
