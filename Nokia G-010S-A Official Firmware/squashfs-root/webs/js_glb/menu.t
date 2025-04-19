/* 
 * vim:ft=javascript
 */

    var all_nodes= {
    name:"all_nodes",
    target:0,
    nodes: 
    [               
        {   name:"<%T('Maintenance')%>",
            target:0,
            nodes:
            [
							{   name:"<%T('Password')%>",
							    target:"user_glb.cgi"
							}, 
							
							{   name:"<%T('SLID Configuration')%>",
							    target:"gpon_config.cgi"
							},
                                                        {
                                                            name:"<%T('Factory Default')%>",
                                                            target:"restore.cgi"
                                                        }
					]
        },

      ]
   }
      
 
