package tk.bblu.spring.timepie.model;

import org.springframework.data.annotation.Id;

public class Done {
    @Id
    public Integer id;
    public Integer code;
    public Integer star;
    public Integer stop;
    public Integer span;
    public float spnd;
    public String name;
    public String alia;
    public String desc;
    public String user;

}
